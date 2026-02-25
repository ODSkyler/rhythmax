import 'dart:convert';
import 'package:dart_des/dart_des.dart';

class JioSaavnDecrypt {
  static const _key = '38346591';

  static String decrypt(
      String encryptedMediaUrl,
      String qualitySuffix,
      ) {
    final encrypted = base64Decode(encryptedMediaUrl);

    final decipher = DES(
      key: _key.codeUnits,
      mode: DESMode.ECB,
      paddingType: DESPaddingType.PKCS7,
    );

    final decrypted = utf8.decode(decipher.decrypt(encrypted));
    return decrypted.replaceAll('_96', qualitySuffix);
  }
}
