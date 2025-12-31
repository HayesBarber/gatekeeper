import 'dart:convert';

import 'package:curveauth_dart/curveauth_dart.dart';

void main() {
  final keyPair = ECCKeyPair.generate();
  final map = keyPair.toJson();
  map['publicKey'] = keyPair.exportPublicKeyRawBase64();
  final json = jsonEncode(map);
  // ignore: avoid_print
  print(json);
}
