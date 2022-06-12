import 'package:mysql_client/mysql_client.dart';

import '../lib/envs.dart' as env;

Future<MySQLConnection> createConnection() async {
  final conn = await MySQLConnection.createConnection(
    host: env.MYSQLHOST,
    port: env.MYSQLPORT,
    userName: env.MYSQLUSER,
    password: env.MYSQLPASS,
    databaseName: env.MYSQLDB,
    secure: false,
  );
  await conn.connect();
  return conn;
}
