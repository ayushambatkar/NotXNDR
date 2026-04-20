import 'dart:math';

import '../config/app_config.dart';

class CodeGenerator {
  static final Random _random = Random.secure();

  static String generate({int minLen = 6, int maxLen = 8}) {
    final chars = AppConfig.allowedCodeCharset;
    final len = minLen + _random.nextInt(maxLen - minLen + 1);
    final buffer = StringBuffer();

    for (var i = 0; i < len; i++) {
      buffer.write(chars[_random.nextInt(chars.length)]);
    }

    return buffer.toString();
  }
}
