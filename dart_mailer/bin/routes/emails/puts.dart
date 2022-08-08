import 'dart:convert';

import 'package:shelf/shelf.dart';
import '../../data/input_body.dart';
import '../../lib/response.dart' as response;
import '../../lib/logger.dart' as logger;
import '../../lib/utils.dart' as utils;
import '../../lib/encryption.dart' as encrypt;
import '../../sql/root.dart' as sql;
import 'package:shelf_router/shelf_router.dart';

Future<Response> updateEmail(Request request) async {
  try {
    final id = request.params['id'];
    final rawData = await request.readAsString();
    Map<String, dynamic> body = jsonDecode(rawData);

    // remove any unwanted values. note: this function does not error if it does not exist
    body.remove("id");
    body.remove("created");
    body.remove("updated");
    body.remove("salt");

    if (body.isEmpty) {
      return response.error(
        "The body cannot be empty after removing invalid values.",
      );
    }

    // check if the password was updated
    if (body.containsKey("password")) {
      Map<String, String> pswdObject = encrypt.encrypt(body['password']);
      body['password'] = pswdObject['password'];
      body['salt'] = pswdObject['salt'];
    }

    // clean lists
    void cleanList(String title) {
      if (body.containsKey(title)) {
        if (body[title].isEmpty) {
          body[title] = "";
        } else {
          body[title] = utils.convertList(body[title]).join(",");
        }
      }
    }

    cleanList("recipient");
    cleanList("cc");
    cleanList("bcc");

    // send the actual update request
    String? resp = await sql.updateEmail(id: id!, body: body);

    if (resp == null) {
      return response
          .internalError("There was an internal error with your request");
    }

    if (resp.isNotEmpty) {
      logger.error(resp);
      return response.internalError('There was an error processing the query');
    }

    return response.success("Successfully updated email object with id: $id");
  } catch (error, stacktrace) {
    logger.error(error.toString(), stacktrace: stacktrace.toString());
    return response
        .internalError("There was an internal error updating the mail object");
  }
}

Future<Response> getEmailsFiltered(Request request) async {
  try {
    final rawData = await request.readAsString();
    final body = jsonDecode(rawData);

    // convert into filter data
    InputBody inputBody = InputBody.fromJson(body);

    // check body validity
    if (!inputBody.isValid()) {
      return response.body("Your body did not meet the criteria");
    }

    var results = await sql.getFilteredBody(inputBody);

    if (results == null) {
      return response
          .internalError("There was an internal error with your request");
    }

    return response.success(
      "Successfully found filtered emails",
      object: results.rows.map((e) => e.typedAssoc()).toList(),
    );
  } catch (error, stacktrace) {
    logger.error(error.toString(), stacktrace: stacktrace.toString());
    return response
        .internalError("There was an internal error getting filtered emails");
  }
}
