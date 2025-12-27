import 'dart:convert';
import 'dart:math';

import 'package:gatekeeper/redis/redis_client.dart';

class ChallengeResponse {
  ChallengeResponse({
    required this.challengeId,
    required this.challenge,
    required this.expiresAt,
  });

  factory ChallengeResponse.random() {
    String randomBytes() {
      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      return base64Encode(bytes);
    }

    final challengeId = randomBytes();
    final challenge = randomBytes();
    final ttlSeconds = Namespace.challenges.ttl?.inSeconds ?? 1;
    final expiresAt = DateTime.now().toUtc().add(Duration(seconds: ttlSeconds));

    return ChallengeResponse(
      challengeId: challengeId,
      challenge: challenge,
      expiresAt: expiresAt,
    );
  }

  factory ChallengeResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeResponse(
      challengeId: json['challenge_id'] as String,
      challenge: json['challenge'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  /// Unique identifier for the challenge
  final String challengeId;

  /// Challenge string to be signed by the client
  final String challenge;

  /// UTC timestamp when the challenge expires
  final DateTime expiresAt;

  Map<String, dynamic> toJson() {
    return {
      'challenge_id': challengeId,
      'challenge': challenge,
      'expires_at': expiresAt.toUtc().toIso8601String(),
    };
  }
}
