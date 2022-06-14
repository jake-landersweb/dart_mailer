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

// debug info
// const MYSQLHOST = "localhost";
// const MYSQLPORT = 3306;
// const MYSQLUSER = "jake";
// const MYSQLPASS = "aloha";
// const MYSQLDB = "sys";
// const MAILTABLE = "Mailer";

// const HOSTNAME = "localhost";
// const HOSTPORT = 8080;

// const APIKEY = "ak-bGFuZGVyc3dlYm1haWxlcgo=";
// const LOGGERPATH = "logs/";

// final ENCRYPTKEY = "b3e2b412-0e1e-4e10-85d6-9ff122d6";
