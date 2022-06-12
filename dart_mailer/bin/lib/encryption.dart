import 'package:encrypt/encrypt.dart';
import 'envs.dart' as env;

Map<String, String> encrypt(String password) {
  final key = Key.fromUtf8(env.ENCRYPTKEY);
  final salt = IV.fromSecureRandom(16);

  final encrypter = Encrypter(AES(key));

  final encrypted = encrypter.encrypt(password, iv: salt);

  return {
    "password": encrypted.base64,
    "salt": salt.base64,
  };
}

String decrypt(String password, String salt) {
  final key = Key.fromUtf8(env.ENCRYPTKEY);
  final encrypter = Encrypter(AES(key));

  return encrypter.decrypt(Encrypted.from64(password), iv: IV.fromBase64(salt));
}

bool compare(String password, String encrypted, String salt) {
  final key = Key.fromUtf8(env.ENCRYPTKEY);
  final encrypter = Encrypter(AES(key));
  final newEncrypted = encrypter.encrypt(password, iv: IV.fromBase64(salt));
  return newEncrypted.base64 == encrypted;
}
