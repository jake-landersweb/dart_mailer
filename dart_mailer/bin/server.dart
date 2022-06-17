import 'dart:async';

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

  // add api routes
  final handler = Pipeline()
      .addMiddleware(logger.middleware())
      .addMiddleware(auth.middleware())
      .addHandler(_router);

  final server = await serve(handler, env.HOSTNAME, env.HOSTPORT);
  logger.createFile();
  logger.log("Sever listening on port ${server.port}");
  print("listening on port: ${server.port}");

  // run a function to send the emails every minute
  while (true) {
    routes.sendAllUnsentEmails();
    await Future.delayed(const Duration(minutes: 1));
  }
}
