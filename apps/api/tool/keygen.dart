import 'dart:convert';

import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';

void main() {
  final keyPair = ECCKeyPair.generate();
  final map = keyPair.toJson();
  map['publicKey'] = keyPair.exportPublicKeyRawBase64();
  final json = jsonEncode(map);
  // ignore: avoid_print
  print(json);
}
