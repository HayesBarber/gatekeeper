import 'dart:convert';
import 'dart:math';

class RandomBytes {
  static String generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
}
