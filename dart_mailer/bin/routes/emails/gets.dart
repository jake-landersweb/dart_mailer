import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import '../../sql/root.dart' as sql;
import '../../lib/response.dart' as response;
import '../../lib/logger.dart' as logger;

Future<Response> getEmails(Request request) async {
  try {
    var results = await sql.getEmails();

    if (results == null) {
      return response
          .internalError("There was an internal error with your request");
    }

    return response.success(
      "Successfully found email objects",
      object: results.rows.map((e) => e.typedAssoc()).toList(),
    );
  } catch (error, stacktrace) {
    logger.error(error.toString(), stacktrace: stacktrace.toString());
    return response.internalError(
        "There was an internal error getting all the mail objects");
  }
}

Future<Response> getEmail(Request request) async {
  try {
    final id = request.params['id'];

    var results = await sql.getEmail(id: id!);

    if (results == null) {
      return response
          .internalError("There was an internal error with your request");
    }

    return response.success(
      "Successfully found email objects",
      object: results.rows.map((e) => e.typedAssoc()).toList(),
    );
  } catch (error, stacktrace) {
    logger.error(error.toString(), stacktrace: stacktrace.toString());
    return response.internalError(
        "There was an internal error getting all the mail objects");
  }
}

Future<Response> getEmailsSentBy(Request request) async {
  try {
    final email = request.params['email'];

    if (email == null) {
      return response.url("email");
    }

    var results = await sql.getEmailsSentByUser(email: email);

    if (results == null) {
      return response
          .internalError("There was an internal error with your request");
    }

    return response.success(
      "Successfully found email objects sent by email: $email",
      object: results.rows.map((e) => e.typedAssoc()).toList(),
    );
  } catch (error, stacktrace) {
    logger.error(error.toString(), stacktrace: stacktrace.toString());
    return response.internalError(
        "There was an internal error getting the mail objects filtered by email");
  }
}

Future<Response> getEmailsReceivedBy(Request request) async {
  try {
    final email = request.params['email'];

    if (email == null) {
      return response.url("email");
    }

    var results = await sql.getEmailsRecievedByUser(email: email);

    if (results == null) {
      return response
          .internalError("There was an internal error with your request");
    }

    return response.success(
      "Successfully found emails recieved by: $email",
      object: results.rows.map((e) => e.typedAssoc()).toList(),
    );
  } catch (error, stacktrace) {
    logger.error(error.toString(), stacktrace: stacktrace.toString());
    return response.internalError(
        "There was an internal error getting the mail objects filtered by email");
  }
}

Future<Response> getEmailsTaggedIn(Request request) async {
  try {
    final email = request.params['email'];

    if (email == null) {
      return response.url("email");
    }

    var results = await sql.getEmailsTaggedUser(email: email);

    if (results == null) {
      return response
          .internalError("There was an internal error with your request");
    }

    return response.success(
      "Successfully found emails that tagged: $email",
      object: results.rows.map((e) => e.typedAssoc()).toList(),
    );
  } catch (error, stacktrace) {
    logger.error(error.toString(), stacktrace: stacktrace.toString());
    return response.internalError(
        "There was an internal error getting the mail objects filtered by email");
  }
}

Future<Response> deleteEmail(Request request) async {
  try {
    final id = request.params['id'];

    var results = await sql.deleteEmail(id: id!);

    if (results == null) {
      return response
          .internalError("There was an internal error with your request");
    }

    return response.success("Successfully deleted email");
  } catch (error, stacktrace) {
    logger.error(error.toString(), stacktrace: stacktrace.toString());
    return response
        .internalError("There was an internal error deleteing the email");
  }
}
