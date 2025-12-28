import 'dart:convert';

import 'package:curveauth_dart/curveauth_dart.dart';

void main() {
  final keyPair = ECCKeyPair.generate();
  final json = jsonEncode(keyPair.toJson());
  // ignore: avoid_print
  print(json);
}
