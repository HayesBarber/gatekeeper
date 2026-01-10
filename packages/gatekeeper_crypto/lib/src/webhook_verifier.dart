import 'package:pointycastle/export.dart';
import 'dart:typed_data';
import 'crypto_utils.dart';

/// A utility class for verifying webhook signatures using HMAC.
///
/// Currently supports GitHub webhooks using HMAC-SHA256.
class WebhookVerifier {
  /// Verifies a GitHub webhook signature against a payload and secret.
  ///
  /// The signature can be either the raw hex string from the 'X-Hub-Signature-256' header
  /// with the 'sha256=' prefix or without it.
  ///
  /// Uses constant-time comparison to prevent timing attacks.
  ///
  /// Returns `true` if the signature is valid, `false` otherwise.
  /// Catches and suppresses any exceptions during verification.
  ///
  /// [payload] is the raw request body as a string.
  /// [signature] is the HMAC signature from the webhook header.
  /// [secret] is the webhook secret key.
  static bool verifyGitHubWebhook({
    required String payload,
    required String signature,
    required String secret,
  }) {
    try {
      final normalizedSignature = _normalizeSignature(signature);
      final key = Uint8List.fromList(secret.codeUnits);
      final data = Uint8List.fromList(payload.codeUnits);

      final hmac = HMac(SHA256Digest(), 64);
      hmac.init(KeyParameter(key));
      hmac.update(data, 0, data.length);

      final mac = Uint8List(hmac.macSize);
      hmac.doFinal(mac, 0);
      final computedSignature = mac
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      return CryptoUtils.constantTimeCompare(
        computedSignature,
        normalizedSignature,
      );
    } catch (_) {
      return false;
    }
  }

  /// Normalizes a signature by removing the 'sha256=' prefix if present.
  ///
  /// Returns the raw hex signature string.
  static String _normalizeSignature(String signature) {
    if (signature.startsWith('sha256=')) {
      return signature.substring(7);
    }
    return signature;
  }

  /// Generates a GitHub webhook signature using HMAC-SHA256.
  ///
  /// Returns the signature as a hex string with the 'sha256=' prefix.
  /// Useful for testing webhook signature verification.
  ///
  /// [payload] is the raw request body as a string.
  /// [secret] is the webhook secret key.
  ///
  /// Returns the HMAC signature string.
  static String generateGitHubWebhookSignature({
    required String payload,
    required String secret,
  }) {
    final key = Uint8List.fromList(secret.codeUnits);
    final data = Uint8List.fromList(payload.codeUnits);

    final hmac = HMac(SHA256Digest(), 64);
    hmac.init(KeyParameter(key));
    hmac.update(data, 0, data.length);

    final mac = Uint8List(hmac.macSize);
    hmac.doFinal(mac, 0);
    final signature = mac
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return 'sha256=$signature';
  }
}
