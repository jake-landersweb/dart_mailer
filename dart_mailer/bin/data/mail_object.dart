import '../lib/utils.dart' as utils;
import 'package:uuid/uuid.dart';
import '../lib/encryption.dart' as encrypt;

class MailObject {
  late String id;
  late String subject;
  late String body;
  late String recipient;
  late String cc;
  late String bcc;
  late String host;
  late int port;
  late String username;
  late String password;
  late String salt;
  late int created;
  int? sentDate;
  late int sentStatus;
  late int sendDate;
  String? sendName;
  String? tags;

  MailObject({
    required this.subject,
    required this.body,
    required List<String> recipient,
    required List<String> cc,
    required List<String> bcc,
    required this.host,
    required this.port,
    required this.username,
    required String password,
    int? sendDate,
    this.sendName,
    this.tags,
  }) {
    // compose id with date
    id = "m-${utils.getEpochDate()}-${Uuid().v4()}";
    // convert into comma separated lists
    this.recipient = recipient.join(',');
    this.cc = cc.join(',');
    this.bcc = bcc.join(',');
    created = utils.getEpochDate();
    sentStatus = 0;
    this.sendDate = sendDate ?? 0;

    // create password and salt
    Map<String, String> obj = encrypt.encrypt(password);
    this.password = obj['password']!;
    salt = obj['salt']!;
  }

  MailObject.fromJson(dynamic json) {
    id = json['id'];
    subject = json['subject'];
    body = json['body'];
    recipient = json['recipient'];
    cc = json['cc'];
    bcc = json['bcc'];
    host = json['host'];
    port = json['port'];
    username = json['username'];
    password = json['password'];
    salt = json['salt'];
    created = json['created'];
    sentDate = json['sentDate'];
    sentStatus = json['sentStatus'];
    sendDate = json['sendDate'];
    sendName = json['sendName'];
    tags = json['tags'];
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "subject": subject,
      "body": body,
      "recipient": recipient,
      "cc": cc,
      "bcc": bcc,
      "host": host,
      "port": port,
      "username": username,
      "password": password,
      "salt": salt,
      "created": created,
      "sentDate": sentDate,
      "sentStatus": sentStatus,
      "sendDate": sendDate,
      "sendName": sendName,
      "tags": tags,
    };
  }
}
