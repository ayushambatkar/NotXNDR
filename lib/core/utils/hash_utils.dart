import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class HashUtils {
  static Future<String> sha256File(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  static String sha256Text(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }
}
