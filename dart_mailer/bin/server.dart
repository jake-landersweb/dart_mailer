import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'lib/auth.dart' as auth;
import 'lib/envs.dart' as env;
import 'lib/logger.dart' as logger;
import 'routes/health.dart' as health;
import 'routes/root.dart' as routes;

// Configure routes.
final _router = Router()
  ..post('/createEmail', routes.createEmail)
  ..get("/emails", routes.getEmails)
  ..put("/emails", routes.getEmailsFiltered)
  ..get("/emails/<id>", routes.getEmail)
  ..put("/emails/<id>", routes.updateEmail)
  ..post("/emails/<id>", routes.sendEmail)
  ..delete("/emails/<id>/delete", routes.deleteEmail)
  ..get("/emailsSetBy/<email>", routes.getEmailsSentBy)
  ..get("/emailsReceivedBy/<email>", routes.getEmailsReceivedBy)
  ..get("/emailsTaggedIn/<email>", routes.getEmailsTaggedIn)
  ..get("/health", health.healthCheck)
  ..get("/", _rootHandler);

Future<Response> _rootHandler(Request req) async {
  return Response.ok('Hello, World!\n');
}

void main(List<String> args) {
  // A socket error from the SMTP server (e.g. "Connection reset by peer") can
  // surface as an uncaught async error and used to kill the whole process.
  // Log it and keep the server and send loop alive instead.
  runZonedGuarded(_run, (Object error, StackTrace stack) {
    logger.error("UNCAUGHT ERROR = $error", stacktrace: stack.toString());
  });
}

Future<void> _run() async {
  var required = [
    "MYSQLHOST",
    "MYSQLPORT",
    "MYSQLUSER",
    "MYSQLPASS",
    "MYSQLDB",
    "MAILTABLE",
    "HOSTNAME",
    "HOSTPORT",
    "APIKEY",
    "ENCRYPTKEY",
    "ISSECURE"
  ];

  for (var i in required) {
    if (!Platform.environment.containsKey(i)) {
      logger.error("$i is required in PATH");
      exit(1);
    }
  }

  // add api routes
  final handler = Pipeline()
      .addMiddleware(logger.middleware())
      .addMiddleware(auth.middleware())
      .addHandler(_router);

  await serve(handler, env.HOSTNAME, env.HOSTPORT);

  stdout.writeln('MAILER ready');

  // run a function to send the emails every minute
  while (true) {
    await Future.delayed(const Duration(seconds: 60));
    try {
      if (await routes.sendAllUnsentEmails()) {
        stdout.writeln('MAILER queue_poll_ok');
      }
    } catch (error, stacktrace) {
      logger.error("ERROR IN send loop = $error",
          stacktrace: stacktrace.toString());
    }
  }
}
