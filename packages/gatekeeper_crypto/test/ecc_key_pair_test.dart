import 'package:test/test.dart';
import 'package:curveauth_dart/curveauth_dart.dart';
import 'dart:convert';

void main() {
  test('ECCKeyPair generates valid key pair', () {
    final keyPair = ECCKeyPair.generate();
    expect(keyPair.privateKey, isNotNull);
    expect(keyPair.publicKey, isNotNull);
  });

  test('ECCKeyPair serializes and deserializes correctly', () {
    final original = ECCKeyPair.generate();
    final jsonMap = original.toJson();
    final restored = ECCKeyPair.fromJson(jsonMap);

    expect(restored.privateKey.d, equals(original.privateKey.d));
    expect(
      restored.publicKey.Q!.x!.toBigInteger(),
      equals(original.publicKey.Q!.x!.toBigInteger()),
    );
    expect(
      restored.publicKey.Q!.y!.toBigInteger(),
      equals(original.publicKey.Q!.y!.toBigInteger()),
    );
  });

  test('ECCKeyPair generates a valid DER-encoded ECDSA signature', () async {
    final keyPair = ECCKeyPair.generate();
    final challenge = 'test-challenge';
    final signature = await keyPair.createSignature(challenge);
    final der = base64Decode(signature);

    expect(der[0], equals(0x30), reason: 'DER must start with SEQUENCE tag');

    final totalLen = der[1];
    expect(
      totalLen + 2,
      equals(der.length),
      reason: 'SEQUENCE length mismatch',
    );

    int offset = 2;

    // First INTEGER (r)
    expect(der[offset], equals(0x02), reason: 'First item must be INTEGER');
    final lenR = der[offset + 1];
    offset += 2 + lenR;

    // Second INTEGER (s)
    expect(der[offset], equals(0x02), reason: 'Second item must be INTEGER');
    final lenS = der[offset + 1];
    offset += 2 + lenS;

    expect(
      offset,
      equals(der.length),
      reason: 'DER signature should be fully parsed',
    );
  });

  test(
    'ECCKeyPair can verify its own signature with instance method',
    () async {
      final keyPair = ECCKeyPair.generate();
      final challenge = 'test-challenge';
      final signature = await keyPair.createSignature(challenge);

      final isValid = keyPair.verifySignature(challenge, signature);
      expect(isValid, isTrue);
    },
  );

  test('ECCKeyPair can verify its own signature with static method', () async {
    final keyPair = ECCKeyPair.generate();
    final challenge = 'test-challenge';
    final signature = await keyPair.createSignature(challenge);
    final publicKeyB64 = keyPair.exportPublicKeyRawBase64();

    final isValid = ECCKeyPair.verifySignatureStatic(
      challenge,
      signature,
      publicKeyB64,
    );
    expect(isValid, isTrue);
  });
}
