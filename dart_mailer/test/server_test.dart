import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  const apiKey = 'fixture-api';
  const headers = {'x-api-key': apiKey};
  late String host;
  late Process server;

  setUpAll(() async {
    final listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = listener.port.toString();
    host = 'http://127.0.0.1:$port';
    await listener.close();

    server = await Process.start('dart', [
      'run',
      'bin/server.dart'
    ], environment: {
      'HOSTNAME': '127.0.0.1',
      'HOSTPORT': port,
      'ISSECURE': 'false',
      'MYSQLHOST': '127.0.0.1',
      'MYSQLPORT': '1',
      'MYSQLUSER': 'fixture',
      'MYSQLPASS': 'fixture',
      'MYSQLDB': 'fixture',
      'MAILTABLE': 'fixture',
      'APIKEY': apiKey,
      'ENCRYPTKEY': 'fixture-encryption-key-123456789',
      'ALERT_SMTP_USERNAME': '',
      'ALERT_SMTP_PASSWORD': '',
    });
    server.stderr.drain<void>();
    await server.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .firstWhere((line) => line == 'MAILER ready');
  });

  tearDownAll(() async {
    server.kill();
    await server.exitCode;
  });

  test('Root', () async {
    final response = await get(Uri.parse('$host/'), headers: headers);
    expect(response.statusCode, 200);
    expect(response.body, 'Hello, World!\n');
  });

  test('404', () async {
    final response = await get(Uri.parse('$host/foobar'), headers: headers);
    expect(response.statusCode, 404);
  });

  test('rejects a malformed To even when Bcc is valid', () async {
    final response = await post(Uri.parse('$host/createEmail'),
        headers: headers,
        body: jsonEncode({
          'subject': 'Account deletion request',
          'body': 'Fixture',
          'recipient': ['non-mailbox'],
          'cc': [],
          'bcc': ['admin@example.test'],
          'host': '127.0.0.1',
          'port': 1,
          'username': 'sender@example.test',
          'password': 'fixture-password',
        }));
    expect(response.statusCode, 422);
    expect(jsonDecode(response.body)['message'],
        'recipient entry 1 is not an email address');
    expect(response.body, isNot(contains('non-mailbox')));
  });

  test('rejects an update with a malformed Bcc before opening the DB',
      () async {
    final response = await put(Uri.parse('$host/emails/fixture'),
        headers: headers,
        body: jsonEncode({
          'bcc': ['valid@example.test', 'invalid']
        }));
    expect(response.statusCode, 422);
    expect(jsonDecode(response.body)['message'],
        'bcc entry 2 is not an email address');
  });
}
