import 'dart:convert';

import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:gatekeeper/redis/redis_client.dart';

class ChallengeResponse {
  ChallengeResponse({
    required this.challengeId,
    required this.challenge,
    required this.expiresAt,
    String? challengeCode,
    this.isVerified = false,
    this.verifiedAt,
    this.isPolled = false,
    this.apiKey,
  }) : challengeCode = challengeCode ?? CryptoUtils.generateThreeDigitCode();

  factory ChallengeResponse.random() {
    final challengeId = CryptoUtils.generateId();
    final challenge = CryptoUtils.generateChallenge();
    final code = CryptoUtils.generateThreeDigitCode();
    final ttlSeconds = Namespace.challenges.ttlSeconds();
    final expiresAt = DateTime.now().toUtc().add(Duration(seconds: ttlSeconds));

    return ChallengeResponse(
      challengeId: challengeId,
      challenge: challenge,
      expiresAt: expiresAt,
      challengeCode: code,
    );
  }

  factory ChallengeResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeResponse(
      challengeId: json['challenge_id'] as String,
      challenge: json['challenge'] as String,
      challengeCode: json['challenge_code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      isPolled: json['is_polled'] as bool? ?? false,
      apiKey: json['api_key'] as String?,
    );
  }

  factory ChallengeResponse.decode(String json) =>
      ChallengeResponse.fromJson(jsonDecode(json) as Map<String, dynamic>);

  /// Unique identifier for the challenge
  final String challengeId;

  /// Challenge string to be signed by the client
  final String challenge;

  /// UTC timestamp when the challenge expires
  final DateTime expiresAt;

  /// 3 digit code for the challenge
  final String challengeCode;

  /// Whether the challenge has been verified
  final bool isVerified;

  /// UTC timestamp when the challenge was verified
  final DateTime? verifiedAt;

  /// Whether the challenge has been polled (consumed)
  final bool isPolled;

  /// API key generated when challenge was verified (for polling)
  final String? apiKey;

  Map<String, dynamic> toJson() {
    return {
      'challenge_id': challengeId,
      'challenge': challenge,
      'challenge_code': challengeCode,
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'is_verified': isVerified,
      'verified_at': verifiedAt?.toUtc().toIso8601String(),
      'is_polled': isPolled,
      'api_key': apiKey,
    };
  }

  ChallengeResponse markAsVerified({required String apiKey}) {
    final now = DateTime.now().toUtc();
    final pollingExpiresAt = now.add(const Duration(seconds: 30));

    return ChallengeResponse(
      challengeId: challengeId,
      challenge: challenge,
      challengeCode: challengeCode,
      expiresAt: pollingExpiresAt,
      isVerified: true,
      verifiedAt: now,
      isPolled: isPolled,
      apiKey: apiKey,
    );
  }

  ChallengeResponse markAsPolled() {
    return ChallengeResponse(
      challengeId: challengeId,
      challenge: challenge,
      challengeCode: challengeCode,
      expiresAt: expiresAt,
      isVerified: isVerified,
      verifiedAt: verifiedAt,
      isPolled: true,
      apiKey: apiKey,
    );
  }

  String encode() => jsonEncode(toJson());
}
