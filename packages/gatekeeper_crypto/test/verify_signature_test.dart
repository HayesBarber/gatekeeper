import 'dart:convert';
import 'dart:typed_data';
import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';
import 'package:test/test.dart';

void main() {
  group('ECCKeyPair verifySignature', () {
    test('verifies a valid signature with instance method', () async {
      final keyPair = ECCKeyPair.generate();
      final message = 'hello world';
      final signature = await keyPair.createSignature(message);

      final isValid = keyPair.verifySignature(message, signature);
      expect(isValid, isTrue);
    });

    test('verifies a valid signature with static method', () async {
      final keyPair = ECCKeyPair.generate();
      final message = 'hello world';
      final signature = await keyPair.createSignature(message);

      final publicKeyB64 = keyPair.exportPublicKeyRawBase64();

      final isValid = ECCKeyPair.verifySignatureStatic(
        message,
        signature,
        publicKeyB64,
      );
      expect(isValid, isTrue);
    });

    test('instance method fails to verify invalid signature', () {
      final keyPair = ECCKeyPair.generate();
      final message = 'hello world';
      final fakeSignature = base64Encode(
        Uint8List.fromList(List.filled(70, 0)),
      );

      final isValid = keyPair.verifySignature(message, fakeSignature);
      expect(isValid, isFalse);
    });

    test('static method fails to verify invalid signature', () {
      final message = 'hello world';
      final fakeSignature = base64Encode(
        Uint8List.fromList(List.filled(70, 0)),
      );
      final fakePublicKey = base64Encode(
        Uint8List.fromList(List.filled(65, 0x04)),
      );

      final isValid = ECCKeyPair.verifySignatureStatic(
        message,
        fakeSignature,
        fakePublicKey,
      );
      expect(isValid, isFalse);
    });
  });
}
