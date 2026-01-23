import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../sql/create_conn.dart';

Future<Response> healthCheck(Request request) async {
  final conn = await createConnection();
  if (conn == null) {
    return Response.internalServerError(
      body: jsonEncode({'status': 'unhealthy', 'database': 'unreachable'}),
      headers: {'content-type': 'application/json'},
    );
  }

  try {
    await conn.execute('SELECT 1');
    return Response.ok(
      jsonEncode({'status': 'healthy', 'database': 'connected'}),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'status': 'unhealthy', 'database': e.toString()}),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await conn.close();
  }
}
