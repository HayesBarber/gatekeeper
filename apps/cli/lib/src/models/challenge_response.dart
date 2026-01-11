class ChallengeResponse {
  ChallengeResponse({
    required this.challengeId,
    required this.challenge,
    required this.expiresAt,
    required this.challengeCode,
  });

  factory ChallengeResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeResponse(
      challengeId: json['challenge_id'] as String,
      challenge: json['challenge'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      challengeCode: json['challenge_code'] as String,
    );
  }

  final String challengeId;
  final String challenge;
  final DateTime expiresAt;
  final String challengeCode;
}
