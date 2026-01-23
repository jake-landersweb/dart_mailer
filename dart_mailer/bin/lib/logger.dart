import 'dart:io';
import 'package:shelf/shelf.dart';

import 'utils.dart' as utils;

void log(String message, {String? stacktrace}) {
  _write("LOG     ", message, stacktrace: stacktrace);
}

void req(String message, {String? stacktrace}) {
  _write("REQUEST ", message, stacktrace: stacktrace);
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
  String line = "${utils.getIsoDate()} | $type | ";
  if (stacktrace != null) {
    line += "$stacktrace | ";
  }
  line += "$message\n";
  stdout.write(line);
}

Middleware middleware() => (innerHandler) {
      return (request) {
        return Future.sync(() => innerHandler(request)).then((response) async {
          req(utils.printRequest(request));
          if (response.statusCode == 200) {
            log(response.context.toString());
          } else {
            error(response.context.toString());
          }
          return response;
        }, onError: (Object err, StackTrace stackTrace) {
          if (err is HijackException) throw err;
          error("There was an error: $err");
          throw err;
        });
      };
    };
