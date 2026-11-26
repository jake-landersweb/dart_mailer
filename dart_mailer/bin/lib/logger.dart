import 'dart:io';
import 'package:shelf/shelf.dart';

void log(String message, {String? stacktrace}) {
  _write("LOG     ", message, stacktrace: stacktrace);
}

void debug(String message, {String? stacktrace}) {
  _write("DEBUG   ", message, stacktrace: stacktrace);
}

void info(String message, {String? stacktrace}) {
  _write("INFO    ", message, stacktrace: stacktrace);
}

void warning(String message, {String? stacktrace}) {
  _write("WARNING ", message, stacktrace: stacktrace);
}

void error(String message, {String? stacktrace}) {
  _write("ERROR   ", message, stacktrace: stacktrace);
}

void critical(String message, {String? stacktrace}) {
  _write("CRITICAL", message, stacktrace: stacktrace);
}

void _write(String type, String message, {String? stacktrace}) {
  if (type == 'ERROR   ' || type == 'CRITICAL') {
    stdout.writeln('MAILER application_error');
  }
}

void queueEvent(String event, String id) {
  if (isQueueId(id)) {
    stdout.writeln('MAILER $event id=$id');
  }
}

bool isQueueId(String id) => id.length == 52 && _queueId.hasMatch(id);

final _queueId = RegExp(
  r'^m-[0-9]{13}-[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',
);

Middleware middleware() => (innerHandler) {
      return (request) async {
        final response = await innerHandler(request);
        if (request.method == 'POST' && request.url.path == 'createEmail') {
          final userAgent = request.headers['user-agent'] ?? '';
          final source =
              userAgent.startsWith('python-requests/') ? 'python-requests' : 'other';
          stdout.writeln(
              'MAILER create_email status=${response.statusCode} source=$source');
        }
        return response;
      };
    };
