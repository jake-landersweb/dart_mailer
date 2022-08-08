import 'package:mysql_client/mysql_client.dart';

import '../lib/envs.dart' as env;
import '../lib/logger.dart' as logger;
import '../routes/root.dart' as routes;

Future<MySQLConnection?> createConnection() async {
  try {
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
  } catch (error, stacktrace) {
    logger.error(
        "Could not establish connection to mysql. ERROR = $error STACKTRACE = $stacktrace");
    routes.sendAltertEmail();
    return null;
  }
}
