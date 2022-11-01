import 'dart:convert';

import 'package:mailer/smtp_server.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';
import '../../data/mail_object.dart';
import '../../sql/create_conn.dart' as mysql;
import '../../lib/response.dart' as response;
import '../../lib/logger.dart' as logger;
import '../../lib/utils.dart' as utils;
import '../../lib/envs.dart' as env;
import '../../lib/encryption.dart' as encrypt;
import '../../sql/root.dart' as sql;
import 'package:mailer/mailer.dart';
import 'package:shelf_router/shelf_router.dart';

Future<Response> createEmail(Request request) async {
  try {
    final rawData = await request.readAsString();
    final body = jsonDecode(rawData);

    // try and convert the body to json
    late MailObject mailObject;
    try {
      mailObject = MailObject(
        subject: body['subject'],
        body: body['body'],
        recipient: utils.convertList(body['recipient']),
        cc: utils.convertList(body['cc']),
        bcc: utils.convertList(body['bcc']),
        host: body['host'],
        port: body['port'],
        username: body['username'],
        password: body['password'],
        sendDate: body['sendDate'] ?? 0,
        sendName: body['sendName'],
        tags: body['tags'],
      );
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

    // make sure this id does not exist
    // var results = await connection.execute(
    //     "SELECT * FROM ${env.MAILTABLE} WHERE id = \"${mailObject.id}\"");
    // if (results.numOfRows > 0) {
    //   logger.error("Duplicate records found with id value in createMailObject");
    //   return response.conflict("id");
    // }

    await connection.execute(
      "INSERT INTO ${env.MAILTABLE} (id, subject, body, recipient, cc, bcc, host, port, username, password, salt, created, sentStatus, sendDate, sendName, tags) VALUES (:id, :subject, :body, :recipient, :cc, :bcc, :host, :port, :username, :password, :salt, :created, :sentStatus, :sendDate, :sendName, :tags)",
      mailObject.toMap(),
    );

    connection.close();

    return response
        .success("Successfully created mail object with id: ${mailObject.id}");
  } catch (error, stacktrace) {
    logger.error(error.toString(), stacktrace: stacktrace.toString());
    return response
        .internalError("There was an internal error creating the mail object");
  }
}

Future<Response> sendEmail(Request request) async {
  try {
    final id = request.params['id'];

    final response = sendEmailHandler(id!);

    return response;
  } catch (error, stacktrace) {
    logger.error(error.toString(), stacktrace: stacktrace.toString());
    return response
        .internalError("There was an internal error creating the mail object");
  }
}

Future<Response> sendEmailHandler(String id) async {
  try {
    final results = await sql.getEmail(id: id);

    if (results == null) {
      return response
          .internalError("There was an internal error with your request");
    }

    if (results.rows.isEmpty) {
      return response.notFound("Email with id $id not found");
    }

    MailObject mailObject =
        MailObject.fromJson(results.rows.toList()[0].typedAssoc());

    final resp = await emailHandler(mailObject);
    return resp;
  } catch (error, stacktrace) {
    logger.error("ERROR IN 'sendEmailHandler()' = $error");
    logger.error("STACKTRACE IN 'sendEmailHandler()' = $stacktrace");
    await sendAltertEmail();
    return response.internalError("There was an issue sending the email");
  }
}

Future<Response> emailHandler(MailObject mailObject) async {
  final smtpServer = SmtpServer(
    mailObject.host,
    port: mailObject.port,
    username: mailObject.username,
    password: encrypt.decrypt(mailObject.password, mailObject.salt),
  );

  late Address address;
  if (mailObject.sendName?.isNotEmpty ?? false) {
    address = Address(mailObject.username, mailObject.sendName);
  } else {
    address = Address(mailObject.username);
  }

  final message = Message()
    ..from = address
    ..recipients.addAll(mailObject.recipient.split(","))
    ..subject = mailObject.subject
    ..html = mailObject.body;

  if (mailObject.cc.isNotEmpty) {
    message.ccRecipients.addAll(mailObject.cc.split(","));
  }
  if (mailObject.bcc.isNotEmpty) {
    message.bccRecipients.addAll(mailObject.bcc.split(","));
  }

  try {
    await send(message, smtpServer);
    // update the mailobject to respect send
    String? updateResp = await sql.updateEmail(id: mailObject.id, body: {
      "sentDate": utils.getEpochDate(),
      "sentStatus": 1,
    });
    if (updateResp?.isEmpty ?? false) {
      return response.success("Successfully sent email: ${mailObject.id}");
    } else {
      return response.internalError(
          "The email was sent, but there was an issue updating the data");
    }
  } on MailerException catch (e) {
    // update the mailobject if it failed to send
    await sql.updateEmail(id: mailObject.id, body: {
      "sentStatus": -1,
      "retryCount": mailObject.retryCount += 1,
    });
    return response.badGateway(e.message);
  }
}

Future<bool> sendAllUnsentEmails() async {
  try {
    var results = await sql.getAllUnsentEmails();
    if (results == null) {
      return false;
    }
    for (var i in results.rows) {
      var resp = await sendEmailHandler(i.typedAssoc()['id']!);
      if (resp.statusCode != 200) {
        return false;
      }
    }
    return true;
  } catch (error, stacktrace) {
    logger.error("ERROR IN 'sendAllUnsentEmails()' = $error");
    logger.error("STACKTRACE IN 'sendAllUnsentEmails()' = $stacktrace");
    await sendAltertEmail();
    return false;
  }
}

Future<void> sendAltertEmail() async {
  try {
    logger.log("SENDING ALERT EMAIL");
    // if there was an error connecting to the database, make sure to catch it and send an alert
    MailObject mailObject = MailObject(
      subject: "MAILER ERROR",
      body: """
              <div>
                <h3>There was an issue sending the emails.</h3>
                <p>Check the server immediately for logs on what went wrong</p>
              </div>
            """,
      recipient: ['jakerlanders@gmail.com'],
      cc: [],
      bcc: [],
      host: "mailen2.cloudsector.net",
      port: 587,
      username: "success@crosschecksports.com",
      password: "us8EweS*9",
      sendDate: 0,
      sendName: "Dart Mailer",
      tags: "admin,error",
    );
    await emailHandler(mailObject);
  } catch (error, stacktrace) {
    logger.error("ERROR IN 'sendAltertEmail()' = $error");
    logger.error("STACKTRACE IN 'sendAltertEmail()' = $stacktrace");
  }
}
