import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../data/mail_object.dart';
import '../../data/recipients.dart';
import '../../lib/encryption.dart' as encrypt;
import '../../lib/envs.dart' as env;
import '../../lib/logger.dart' as logger;
import '../../lib/response.dart' as response;
import '../../lib/utils.dart' as utils;
import '../../sql/create_conn.dart' as mysql;
import '../../sql/root.dart' as sql;

Future<Response> createEmail(Request request) async {
  try {
    logger.info("CREATE EMAIL");
    final rawData = await request.readAsString();
    final body = jsonDecode(rawData);

    // try and convert the body to json
    late MailObject mailObject;
    try {
      mailObject = MailObject(
        subject: body['subject'],
        body: body['body'],
        recipient: normalizeRecipients(
          'recipient',
          utils.convertList(body['recipient']),
          required: true,
        ),
        cc: normalizeRecipients('cc', utils.convertList(body['cc'])),
        bcc: normalizeRecipients('bcc', utils.convertList(body['bcc'])),
        host: body['host'],
        port: body['port'],
        username: body['username'],
        password: body['password'],
        sendDate: body['sendDate'] ?? 0,
        sendName: body['sendName'],
        tags: body['tags'],
      );
    } on FormatException catch (error) {
      return response.basic(422, error.message);
    } catch (error, stacktrace) {
      logger.error(error.toString(), stacktrace: stacktrace.toString());
      return response.body(
        "Failed to parse the body into the object. Perhaps the body is incorect?",
      );
    }

    // create the mysql connection
    MySQLConnection? connection = await mysql.createConnection();

    if (connection == null) {
      return response
          .internalError("There was an internal error with your request");
    }

    try {
      await connection.execute(
        "INSERT INTO ${env.MAILTABLE} (id, subject, body, recipient, cc, bcc, host, port, username, password, salt, created, sentStatus, sendDate, sendName, tags) VALUES (:id, :subject, :body, :recipient, :cc, :bcc, :host, :port, :username, :password, :salt, :created, :sentStatus, :sendDate, :sendName, :tags)",
        mailObject.toMap(),
      );

      logger.queueEvent("queue_inserted", mailObject.id);
      return response.success(
          "Successfully created mail object with id: ${mailObject.id}");
    } finally {
      await connection.close();
    }
  } catch (error, stacktrace) {
    logger.error(error.toString(), stacktrace: stacktrace.toString());
    return response
        .internalError("There was an internal error creating the mail object");
  }
}

typedef _DeliveryResult = ({Response response, String? alert});

Future<Response> sendEmail(Request request) async {
  final result = await _sendQueuedEmail(request.params['id']!);
  return result.response;
}

final _inFlight = <String, Future<_DeliveryResult>>{};

Future<_DeliveryResult> _sendQueuedEmail(String id, {bool scheduled = false}) {
  return _inFlight.putIfAbsent(
    id,
    () => _loadAndDeliver(id, scheduled: scheduled).whenComplete(() {
      _inFlight.remove(id);
    }),
  );
}

Future<_DeliveryResult> _loadAndDeliver(String id,
    {required bool scheduled}) async {
  try {
    final results = await sql.getEmail(id: id);
    if (results == null) {
      return _queueError(id, 'Could not read the queue row');
    }
    if (results.rows.isEmpty) {
      return (
        response: response.notFound('Email with id $id not found'),
        alert: null,
      );
    }
    final mail = MailObject.fromJson(results.rows.first.typedAssoc());
    if (scheduled &&
        (mail.sentStatus == 1 ||
            mail.retryCount >= sql.maxSendAttempts ||
            mail.sendDate >= utils.getEpochDate())) {
      return (
        response: response.success('Email is no longer due'),
        alert: null
      );
    }
    return await _deliver(mail);
  } catch (_) {
    return _queueError(id, 'Could not process the queue row');
  }
}

List<String> _storedRecipients(String field, String value) {
  return normalizeRecipients(
    field,
    value.isEmpty ? [] : [value],
    required: field == 'recipient',
  );
}

Future<_DeliveryResult> _deliver(MailObject mail) async {
  final message = Message()
    ..from = Address(mail.username, mail.sendName)
    ..subject = mail.subject
    ..html = mail.body;

  try {
    message.recipients.addAll(_storedRecipients('recipient', mail.recipient));
    message.ccRecipients.addAll(_storedRecipients('cc', mail.cc));
    message.bccRecipients.addAll(_storedRecipients('bcc', mail.bcc));
  } on FormatException catch (error) {
    return _recordFailure(mail, error.message, permanent: true);
  }

  try {
    final smtpServer = SmtpServer(
      mail.host,
      port: mail.port,
      username: mail.username,
      password: encrypt.decrypt(mail.password, mail.salt),
    );
    logger.queueEvent('smtp_attempt', mail.id);
    await send(message, smtpServer);
  } on SmtpMessageValidationException {
    return _recordFailure(mail, 'SMTP message validation failed',
        permanent: true);
  } catch (error) {
    return _recordFailure(mail, _smtpFailure(error));
  }

  logger.queueEvent('smtp_accepted', mail.id);
  final updated = await sql.updateEmail(id: mail.id, body: {
    'sentDate': utils.getEpochDate(),
    'sentStatus': 1,
  });
  if (updated != '') {
    return _queueError(
        mail.id, 'SMTP accepted the email, but sent status could not be saved');
  }
  return (
    response: response.success('Successfully sent email: ${mail.id}'),
    alert: null
  );
}

Future<_DeliveryResult> _recordFailure(
  MailObject mail,
  String detail, {
  bool permanent = false,
}) async {
  final attempts = permanent ? sql.maxSendAttempts : mail.retryCount + 1;
  final updated = await sql.updateEmail(id: mail.id, body: {
    'sentStatus': -1,
    'retryCount': attempts,
  });
  if (updated != '') {
    return _queueError(mail.id, '$detail. Failed status could not be saved');
  }
  if (permanent) {
    logger.queueEvent('queue_invalid_message', mail.id);
    return (response: response.basic(422, detail), alert: null);
  }
  logger.error(detail);
  return (
    response: response.badGateway(detail),
    alert:
        attempts >= sql.maxSendAttempts ? _forQueueId(mail.id, detail) : null,
  );
}

_DeliveryResult _queueError(String id, String detail) {
  logger.error(detail);
  return (
    response: response.internalError(detail),
    alert: _forQueueId(id, detail)
  );
}

String _forQueueId(String id, String detail) {
  return logger.isQueueId(id) ? '$id: $detail' : detail;
}

String _smtpFailure(Object error) => switch (error) {
      SmtpClientAuthenticationException() => 'SMTP authentication failed',
      SmtpUnsecureException() || TlsException() => 'SMTP TLS failed',
      SmtpNoGreetingException() => 'SMTP server did not send a greeting',
      SmtpClientCommunicationException() =>
        'SMTP server rejected a command or message',
      TimeoutException() => 'SMTP connection or send timed out',
      SocketException() => 'SMTP network connection failed',
      _ => 'Unexpected error preparing or sending the email',
    };

Future<bool> sendAllUnsentEmails() async {
  final alerts = <String>[];
  var failed = false;
  try {
    final results = await sql.getAllUnsentEmails();
    if (results == null) {
      throw StateError('Could not read due emails');
    }
    for (final row in results.rows) {
      final result =
          await _sendQueuedEmail(row.typedAssoc()['id']!, scheduled: true);
      if (result.alert case final detail?) {
        alerts.add(detail);
      }
      if (result.response.statusCode >= 500) {
        failed = true;
      }
    }
  } catch (_) {
    logger.error('Could not read the due-email queue');
    alerts.add('Could not read the due-email queue');
    failed = true;
  }
  if (alerts.isNotEmpty) {
    final details = alerts.take(10).join('\n');
    final extra = alerts.length > 10
        ? '\nAdditional failures: ${alerts.length - 10}'
        : '';
    await _sendAlertEmail('$details$extra');
  }
  return !failed;
}

Future<void> _sendAlertEmail(String details) async {
  final username = env.ALERT_SMTP_USERNAME;
  final password = env.ALERT_SMTP_PASSWORD;
  if (username == null ||
      username.isEmpty ||
      password == null ||
      password.isEmpty) {
    return;
  }
  try {
    final message = Message()
      ..from = Address(username, 'Dart Mailer')
      ..recipients.add('jakerlanders@gmail.com')
      ..subject = 'MAILER ERROR'
      ..text = 'There was an issue sending the emails.\n\n$details';
    await send(
        message,
        SmtpServer(
          'mailen2.cloudsector.net',
          port: 587,
          username: username,
          password: password,
        ));
    stdout.writeln('MAILER alert_accepted');
  } catch (error) {
    logger.error(_smtpFailure(error));
  }
}
