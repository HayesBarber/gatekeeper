import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:gatekeeper_crypto/src/crypto_utils.dart';
import 'package:pointycastle/export.dart';

/// Represents an elliptic curve key pair using the secp256r1 curve.
///
/// Provides functionality to:
/// - Generate new key pairs
/// - Serialize/deserialize keys to/from JSON
/// - Export public keys in raw base64 format
/// - Create ECDSA signatures for messages
class ECCKeyPair {
  final ECPrivateKey privateKey;
  final ECPublicKey publicKey;

  ECCKeyPair._(this.privateKey, this.publicKey);

  /// Generates a new ECC key pair using the secp256r1 curve.
  ///
  /// Returns an [ECCKeyPair] containing both private and public keys.
  factory ECCKeyPair.generate() {
    final ecDomain = ECDomainParameters('secp256r1');
    final keyGen = ECKeyGenerator();

    final secureRandom = FortunaRandom();
    final src = Random.secure();
    final seed = Uint8List.fromList(List.generate(32, (_) => src.nextInt(256)));
    secureRandom.seed(KeyParameter(seed));

    keyGen.init(
      ParametersWithRandom(ECKeyGeneratorParameters(ecDomain), secureRandom),
    );
    final pair = keyGen.generateKeyPair();

    final priv = pair.privateKey;
    final pub = pair.publicKey;

    return ECCKeyPair._(priv, pub);
  }

  /// Constructs an [ECCKeyPair] from a JSON map.
  ///
  /// Expects `privateKey`, `publicKeyX`, and `publicKeyY` entries in hex string format.
  ///
  /// Throws [ArgumentError] if required fields are missing or malformed.
  factory ECCKeyPair.fromJson(Map<String, String> json) {
    final ecDomain = ECDomainParameters('secp256r1');

    final dStr = json['privateKey'];
    final xStr = json['publicKeyX'];
    final yStr = json['publicKeyY'];

    if (dStr == null || xStr == null || yStr == null) {
      throw ArgumentError('Missing required key material in JSON map.');
    }

    final d = BigInt.parse(dStr, radix: 16);
    final x = BigInt.parse(xStr, radix: 16);
    final y = BigInt.parse(yStr, radix: 16);
    final Q = ecDomain.curve.createPoint(x, y);
    final privateKey = ECPrivateKey(d, ecDomain);
    final publicKey = ECPublicKey(Q, ecDomain);

    return ECCKeyPair._(privateKey, publicKey);
  }

  /// Serializes the ECC key pair to a JSON-compatible map with hex string values.
  ///
  /// Returns a [Map] with keys: `privateKey`, `publicKeyX`, and `publicKeyY`.
  ///
  /// Throws [StateError] if any component is null or invalid.
  Map<String, String> toJson() {
    final d = privateKey.d;
    final q = publicKey.Q;
    if (d == null || q == null || q.x == null || q.y == null) {
      throw StateError('Invalid ECC key: missing required components.');
    }

    final privHex = d.toRadixString(16).padLeft(64, '0');
    final pubX = q.x!.toBigInteger()!.toRadixString(16).padLeft(64, '0');
    final pubY = q.y!.toBigInteger()!.toRadixString(16).padLeft(64, '0');

    return {'privateKey': privHex, 'publicKeyX': pubX, 'publicKeyY': pubY};
  }

  /// Exports the public key in uncompressed format as a base64-encoded string.
  ///
  /// The output is a 65-byte array: 0x04 || X (32 bytes) || Y (32 bytes).
  ///
  /// Throws [StateError] if the public key is incomplete.
  String exportPublicKeyRawBase64() {
    final q = publicKey.Q;
    if (q == null || q.x == null || q.y == null) {
      throw StateError('Public key is incomplete.');
    }

    final xBytes = q.x!.toBigInteger()!.toRadixString(16).padLeft(64, '0');
    final yBytes = q.y!.toBigInteger()!.toRadixString(16).padLeft(64, '0');

    final xList = List<int>.generate(
      32,
      (i) => int.parse(xBytes.substring(i * 2, i * 2 + 2), radix: 16),
    );
    final yList = List<int>.generate(
      32,
      (i) => int.parse(yBytes.substring(i * 2, i * 2 + 2), radix: 16),
    );

    final pubBytes = Uint8List(65);
    pubBytes[0] = 0x04;
    pubBytes.setRange(1, 33, xList);
    pubBytes.setRange(33, 65, yList);

    return base64Encode(pubBytes);
  }

  /// Creates an ECDSA signature for the given challenge string.
  ///
  /// Uses SHA-256 for hashing and encodes the signature in DER format, then base64.
  ///
  /// Returns a [Future] that completes with a base64-encoded DER signature string.
  Future<String> createSignature(String challenge) async {
    final signer = Signer('SHA-256/ECDSA');
    final random = FortunaRandom();
    final src = Random.secure();
    final seed = Uint8List.fromList(List.generate(32, (_) => src.nextInt(256)));
    random.seed(KeyParameter(seed));

    signer.init(
      true,
      ParametersWithRandom(
        PrivateKeyParameter<ECPrivateKey>(privateKey),
        random,
      ),
    );

    final message = Uint8List.fromList(challenge.codeUnits);
    final sig = signer.generateSignature(message) as ECSignature;

    final der = CryptoUtils.encodeDer(sig.r, sig.s);
    return base64Encode(der);
  }

  /// Verifies a base64-encoded ECDSA signature against a message using this key pair's public key.
  ///
  /// The signature must be DER-encoded and base64-encoded.
  ///
  /// Returns `true` if the signature is valid, `false` otherwise.
  /// Catches and suppresses any exceptions during decoding or verification.
  ///
  /// [message] is the original plaintext message that was signed.
  /// [signatureB64] is the base64-encoded DER ECDSA signature.
  bool verifySignature(String message, String signatureB64) {
    try {
      final signatureBytes = base64Decode(signatureB64);
      final sig = CryptoUtils.decodeDer(signatureBytes);

      final signer = Signer('SHA-256/ECDSA');
      signer.init(false, PublicKeyParameter<ECPublicKey>(publicKey));

      final messageBytes = Uint8List.fromList(message.codeUnits);
      return signer.verifySignature(messageBytes, sig);
    } catch (_) {
      return false;
    }
  }

  /// Verifies a base64-encoded ECDSA signature against a message and a base64-encoded public key.
  ///
  /// The signature must be DER-encoded and base64-encoded.
  /// The public key must be a base64-encoded uncompressed ECC key (65 bytes, starting with 0x04).
  ///
  /// Returns `true` if the signature is valid, `false` otherwise.
  /// Catches and suppresses any exceptions during decoding or verification.
  ///
  /// [message] is the original plaintext message that was signed.
  /// [signatureB64] is the base64-encoded DER ECDSA signature.
  /// [publicKeyB64] is the base64-encoded uncompressed ECC public key.
  static bool verifySignatureStatic(
    String message,
    String signatureB64,
    String publicKeyB64,
  ) {
    try {
      final signatureBytes = base64Decode(signatureB64);
      final publicKey = CryptoUtils.loadPublicKeyRawBase64(publicKeyB64);
      final sig = CryptoUtils.decodeDer(signatureBytes);

      final signer = Signer('SHA-256/ECDSA');
      signer.init(false, PublicKeyParameter<ECPublicKey>(publicKey));

      final messageBytes = Uint8List.fromList(message.codeUnits);
      return signer.verifySignature(messageBytes, sig);
    } catch (_) {
      return false;
    }
  }
}
