import 'package:mysql_client/mysql_client.dart';

import '../lib/envs.dart' as env;

Future<MySQLConnection> createConnection() async {
  // print(env.MYSQLHOST);
  // print(env.MYSQLPORT);
  // print(env.MYSQLHOST);
  // print(env.MYSQLPORT);
  // print(env.MYSQLUSER);
  // print(env.MYSQLPASS);
  // print(env.MYSQLDB);
  // print(env.ISSECURE);
  final conn = await MySQLConnection.createConnection(
    host: env.MYSQLHOST,
    port: env.MYSQLPORT,
    userName: env.MYSQLUSER,
    password: env.MYSQLPASS,
    databaseName: env.MYSQLDB,
    secure: env.ISSECURE,
  );
  await conn.connect();
  return conn;
}
