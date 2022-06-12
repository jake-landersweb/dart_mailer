import 'dart:io';
import 'package:shelf/shelf.dart';

import 'utils.dart' as utils;
import 'envs.dart' as env;

// create a new log file for each instance this application runs
// File _loggerFile = File('../../logs/${utils.getEpochDate()}.txt');

late File _loggerFile;

void createFile() {
  String filename = '${env.LOGGERPATH}${utils.getIsoDate()}.txt';
  File(filename).createSync(recursive: true);
  _loggerFile = File(filename);
  String val =
      "${utils.getIsoDate()} | STARTING MAILER SERVER FOR HOST: ${env.HOSTNAME} PORT: ${env.HOSTPORT}'\n";
  _loggerFile.writeAsStringSync(
    val,
    mode: FileMode.append,
  );
  _loggerFile.writeAsStringSync(
    "${"-" * 50}\n",
    mode: FileMode.append,
  );
  stdout.write("LOGGER FILE CREATED AT: '${_loggerFile.absolute}'\n");
  stdout.write(val);
}

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
  _loggerFile.writeAsStringSync(line, mode: FileMode.append);
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
