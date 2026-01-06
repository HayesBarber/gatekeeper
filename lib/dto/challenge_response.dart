import 'dart:convert';

import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/util/random_bytes.dart';

class ChallengeResponse {
  ChallengeResponse({
    required this.challengeId,
    required this.challenge,
    required this.expiresAt,
  });

  factory ChallengeResponse.random() {
    final challengeId = RandomBytes.generate();
    final challenge = RandomBytes.generate();
    final ttlSeconds = Namespace.challenges.ttlSeconds();
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

  factory ChallengeResponse.decode(String json) =>
      ChallengeResponse.fromJson(jsonDecode(json) as Map<String, dynamic>);

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

  String encode() => jsonEncode(toJson());
}
