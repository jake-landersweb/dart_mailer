import 'package:mysql_client/mysql_client.dart';
import 'root.dart' as sql;
import '../lib/envs.dart' as env;
import '../lib/utils.dart' as utils;

Future<IResultSet> dyn({
  required String column,
  required String opp,
  required String value,
}) async {
  MySQLConnection connection = await sql.createConnection();
  var results = await connection.execute(
    "SELECT * FROM ${env.MAILTABLE} WHERE $column $opp :val",
    {"val": value},
  );
  return results;
}

Future<IResultSet> getEmails() async {
  MySQLConnection connection = await sql.createConnection();
  var results = await connection.execute("SELECT * FROM ${env.MAILTABLE}");
  return results;
}

Future<IResultSet> getEmail({required String id}) async {
  MySQLConnection connection = await sql.createConnection();
  var results = await connection.execute(
    "SELECT * FROM ${env.MAILTABLE} WHERE id = :id",
    {"id": id},
  );
  return results;
}

Future<IResultSet> getEmailsSentByUser({required String email}) async {
  MySQLConnection connection = await sql.createConnection();
  var results = await connection.execute(
    "SELECT * FROM ${env.MAILTABLE} WHERE username = :username",
    {"username": email},
  );
  return results;
}

Future<IResultSet> getEmailsRecievedByUser({required String email}) async {
  MySQLConnection connection = await sql.createConnection();
  var results = await connection.execute(
    "SELECT * FROM ${env.MAILTABLE} WHERE recipient LIKE :email",
    {"email": email},
  );
  return results;
}

Future<IResultSet> getEmailsTaggedUser({required String email}) async {
  MySQLConnection connection = await sql.createConnection();
  var results = await connection.execute(
    "SELECT * FROM ${env.MAILTABLE} WHERE cc LIKE :email OR bcc LIKE :email",
    {"email": email},
  );
  return results;
}

Future<String> updateEmail({
  required String id,
  required Map<String, dynamic> body,
}) async {
  try {
    String queryString = "";
    // loop through objects and create dynamic update string
    for (var obj in body.entries) {
      if (obj.key == body.entries.first.key) {
        queryString += "${obj.key} = :${obj.key}";
      } else {
        queryString += ", ${obj.key} = :${obj.key}";
      }
    }

    print(queryString);
    print(body);

    MySQLConnection connection = await sql.createConnection();
    await connection.execute(
      "UPDATE ${env.MAILTABLE} SET $queryString WHERE id = '$id'",
      body,
    );
    return "";
  } catch (error, stacktrace) {
    return "$error $stacktrace";
  }
}

Future<IResultSet> getAllUnsentEmails() async {
  MySQLConnection connection = await sql.createConnection();
  var results = await connection.execute(
    "SELECT id FROM ${env.MAILTABLE} WHERE sentStatus != :sentStatus AND sendDate < :sendDate",
    {
      "sentStatus": 1,
      "sendDate": utils.getEpochDate(),
    },
  );
  return results;
}
