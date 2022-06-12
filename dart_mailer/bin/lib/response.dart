import 'dart:convert';
import 'package:shelf/shelf.dart';

Response success(String message, {dynamic object}) {
  var body = {
    "status": 200,
    "message": message,
  };
  if (object != null) {
    body['body'] = object;
  }
  return Response(
    200,
    body: jsonEncode(body),
    headers: {"Content-Type": "application/json"},
    context: {"200": message},
  );
}

Response body(String value) {
  return Response(
    422,
    body: jsonEncode({
      "status": 422,
      "message": "The value: $value is required in the body",
    }),
    headers: {"Content-Type": "application/json"},
    context: {"422": "The value: $value is required in the body"},
  );
}

Response url(String value) {
  return Response(
    422,
    body: jsonEncode({
      "status": 422,
      "message": "The value: $value is required in the url",
    }),
    headers: {"Content-Type": "application/json"},
    context: {"422": "The value: $value is required in the body"},
  );
}

Response basic(int status, String message) {
  return Response(
    status,
    body: jsonEncode({"status": status, "message": message}),
    headers: {"Content-Type": "application/json"},
    context: {status.toString(): message},
  );
}

Response notFound(String message) {
  return Response(
    404,
    body: jsonEncode({"status": 404, "message": message}),
    headers: {"Content-Type": "application/json"},
    context: {"404": message},
  );
}

Response internalError(String message) {
  return Response(
    500,
    body: jsonEncode({"status": 500, "message": message}),
    headers: {"Content-Type": "application/json"},
    context: {"500": message},
  );
}

Response auth() {
  return Response(
    403,
    body: jsonEncode({
      "status": 403,
      "message": "You are not permitted to view this resource"
    }),
    headers: {"Content-Type": "application/json"},
    context: {"403": "You are not permitted to view this resource"},
  );
}

Response conflict(String value) {
  return Response(
    409,
    body: jsonEncode({
      "status": 409,
      "message": "The value: $value already exists in this set",
    }),
    headers: {"Content-Type": "application/json"},
    context: {"409": "The value: $value already exists in this set"},
  );
}

Response badGateway(String value) {
  int status = 502;
  return Response(
    status,
    body: jsonEncode({
      "status": status,
      "message": value,
    }),
    headers: {"Content-Type": "application/json"},
    context: {"$status": value},
  );
}

Response error(String value) {
  int status = 400;
  return Response(
    status,
    body: jsonEncode({
      "status": status,
      "message": value,
    }),
    headers: {"Content-Type": "application/json"},
    context: {"$status": value},
  );
}
