import 'package:mysql_client/mysql_client.dart';
import '../data/input_body.dart';
import 'root.dart' as sql;
import '../lib/envs.dart' as env;
import '../lib/utils.dart' as utils;

Future<IResultSet?> dyn({
  required String column,
  required String opp,
  required String value,
}) async {
  MySQLConnection? connection = await sql.createConnection();
  if (connection == null) {
    return null;
  }
  var results = await connection.execute(
    "SELECT * FROM ${env.MAILTABLE} WHERE $column $opp :val",
    {"val": value},
  );
  connection.close();
  return results;
}

Future<IResultSet?> getEmails() async {
  MySQLConnection? connection = await sql.createConnection();
  if (connection == null) {
    return null;
  }
  var results = await connection.execute("SELECT * FROM ${env.MAILTABLE}");
  connection.close();
  return results;
}

Future<IResultSet?> getEmail({required String id}) async {
  MySQLConnection? connection = await sql.createConnection();
  if (connection == null) {
    return null;
  }
  var results = await connection.execute(
    "SELECT * FROM ${env.MAILTABLE} WHERE id = :id",
    {"id": id},
  );
  connection.close();
  return results;
}

Future<IResultSet?> getEmailsSentByUser({required String email}) async {
  MySQLConnection? connection = await sql.createConnection();
  if (connection == null) {
    return null;
  }
  var results = await connection.execute(
    "SELECT * FROM ${env.MAILTABLE} WHERE username = :username",
    {"username": email},
  );
  connection.close();
  return results;
}

Future<IResultSet?> getEmailsRecievedByUser({required String email}) async {
  MySQLConnection? connection = await sql.createConnection();
  if (connection == null) {
    return null;
  }
  var results = await connection.execute(
    "SELECT * FROM ${env.MAILTABLE} WHERE recipient LIKE '%$email%'",
  );
  return results;
}

Future<IResultSet?> getEmailsTaggedUser({required String email}) async {
  MySQLConnection? connection = await sql.createConnection();
  if (connection == null) {
    return null;
  }
  var results = await connection.execute(
    "SELECT * FROM ${env.MAILTABLE} WHERE cc LIKE '%$email%' OR bcc LIKE '%$email%'",
  );
  connection.close();
  return results;
}

Future<String?> updateEmail({
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

    MySQLConnection? connection = await sql.createConnection();
    if (connection == null) {
      return null;
    }
    await connection.execute(
      "UPDATE ${env.MAILTABLE} SET $queryString WHERE id = '$id'",
      body,
    );
    connection.close();
    return "";
  } catch (error, stacktrace) {
    return "$error $stacktrace";
  }
}

Future<IResultSet?> getAllUnsentEmails() async {
  MySQLConnection? connection = await sql.createConnection();
  if (connection == null) {
    return null;
  }
  var results = await connection.execute(
    "SELECT id FROM ${env.MAILTABLE} WHERE sentStatus != :sentStatus AND sendDate < :sendDate AND (retryCount < :retryCount OR retryCount IS NULL)",
    {
      "sentStatus": 1,
      "sendDate": utils.getEpochDate(),
      "retryCount": 4,
    },
  );
  connection.close();
  return results;
}

Future<IResultSet?> getFilteredBody(InputBody body) async {
  // compose return values
  String selects = "";
  if (body.returnValues.isEmpty) {
    selects = "*";
  } else if (body.returnValues.length == 1 && body.returnValues[0] == "COUNT") {
    selects = "COUNT(*)";
  } else {
    for (int i = 0; i < body.returnValues.length; i++) {
      if (i == 0) {
        selects += body.returnValues[i];
      } else {
        selects += ", ${body.returnValues[i]}";
      }
    }
  }

  // compose filters
  late String filters;
  if (body.filters.isEmpty) {
    filters = "";
  } else {
    filters = "WHERE ";
    for (var i = 0; i < body.filters.length; i++) {
      if (i == 0) {
        filters += body.filters[i].composeSQL();
      } else {
        filters +=
            " ${body.filters[i].getChainCommand()} ${body.filters[i].composeSQL()}";
      }
    }
  }

  String queryString =
      "SELECT $selects FROM ${env.MAILTABLE} $filters ORDER BY id DESC";

  // if limit and page size are specified
  if (body.pageSize != null) {
    queryString +=
        " LIMIT ${(((body.page ?? 1) - 1) * body.pageSize!)},${body.pageSize!}";
  }

  MySQLConnection? connection = await sql.createConnection();
  if (connection == null) {
    return null;
  }
  var results = await connection.execute(queryString);
  connection.close();
  return results;
}
