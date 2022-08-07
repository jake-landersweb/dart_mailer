import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'lib/envs.dart' as env;
import 'routes/root.dart' as routes;
import 'lib/utils.dart' as utils;
import 'lib/logger.dart' as logger;
import 'lib/auth.dart' as auth;

// Configure routes.
final _router = Router()
  ..post('/createEmail', routes.createEmail)
  ..get("/emails", routes.getEmails)
  ..put("/emails", routes.getEmailsFiltered)
  ..get("/emails/<id>", routes.getEmail)
  ..put("/emails/<id>", routes.updateEmail)
  ..post("/emails/<id>", routes.sendEmail)
  ..get("/emailsSetBy/<email>", routes.getEmailsSentBy)
  ..get("/emailsReceivedBy/<email>", routes.getEmailsReceivedBy)
  ..get("/emailsTaggedIn/<email>", routes.getEmailsTaggedIn)
  ..get("/", _rootHandler);

Future<Response> _rootHandler(Request req) async {
  return Response.ok('Hello, World!\n');
}

void main(List<String> args) async {
  print("Starting MAILER server at: ${utils.getIsoDate()}");

  logger.createFile();

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
    "LOGGERPATH",
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

  final server = await serve(handler, env.HOSTNAME, env.HOSTPORT);

  logger.log("Sever listening on port ${server.port}");

  // run a function to send the emails every minute
  while (true) {
    var response = await routes.sendAllUnsentEmails();
    if (!response) {
      await routes.sendAltertEmail();
    }
    await Future.delayed(const Duration(minutes: 1));
  }
}
