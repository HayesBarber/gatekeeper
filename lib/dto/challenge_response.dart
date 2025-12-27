class ChallengeResponse {
  ChallengeResponse({
    required this.challengeId,
    required this.challenge,
    required this.expiresAt,
  });

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

  /// Example for reference
  static const example = {
    'challenge_id': '83fcfcf6e2e84df7b7a84db6c52934f7',
    'challenge': 'e9f34c6d9c0b4f74a1f9f3a2e5a1b3c4',
    'expires_at': '2025-07-31T23:59:59Z',
  };
}
