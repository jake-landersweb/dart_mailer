// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:io' show Platform;

// prod info
String MYSQLHOST = Platform.environment['MYSQLHOST']!;
int MYSQLPORT = int.tryParse(Platform.environment['MYSQLPORT']!) ?? 3306;
String MYSQLUSER = Platform.environment['MYSQLUSER']!;
String MYSQLPASS = Platform.environment['MYSQLPASS']!;
String MYSQLDB = Platform.environment['MYSQLDB']!;
String MAILTABLE = Platform.environment['MAILTABLE']!;

String HOSTNAME = Platform.environment['HOSTNAME']!;
int HOSTPORT = int.tryParse(Platform.environment['HOSTPORT']!) ?? 8080;

String APIKEY = Platform.environment['APIKEY']!;
String LOGGERPATH = Platform.environment['LOGGERPATH']!;

String ENCRYPTKEY = Platform.environment['ENCRYPTKEY']!;

bool ISSECURE = Platform.environment['ISSECURE'] == "true";
