import 'dart:convert';

import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';

class ChallengeVerificationResponse {
  ChallengeVerificationResponse({
    required this.authToken,
    required this.expiresAt,
  });

  factory ChallengeVerificationResponse.random({Duration? ttl}) {
    final token = CryptoUtils.generateBytes();
    final effectiveTtl = ttl ?? const Duration(minutes: 5);
    final expiresAt = DateTime.now().toUtc().add(effectiveTtl);

    return ChallengeVerificationResponse(
      authToken: token,
      expiresAt: expiresAt,
    );
  }

  factory ChallengeVerificationResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeVerificationResponse(
      authToken: json['api_key'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  factory ChallengeVerificationResponse.decode(String json) =>
      ChallengeVerificationResponse.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

  /// Issued API key tied to this client
  final String authToken;

  /// UTC timestamp when the api key expires
  final DateTime expiresAt;

  Map<String, dynamic> toJson() {
    return {
      'api_key': authToken,
      'expires_at': expiresAt.toUtc().toIso8601String(),
    };
  }

  String encode() => jsonEncode(toJson());
}
