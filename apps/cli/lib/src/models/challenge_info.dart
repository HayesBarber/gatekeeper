class ChallengeInfo {
  ChallengeInfo({
    required this.challengeId,
    required this.challenge,
    required this.challengeCode,
    required this.expiresAt,
  });

  factory ChallengeInfo.fromJson(Map<String, dynamic> json) {
    return ChallengeInfo(
      challengeId: json['challenge_id'] as String,
      challenge: json['challenge'] as String,
      challengeCode: json['challenge_code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  final String challengeId;
  final String challenge;
  final String challengeCode;
  final DateTime expiresAt;
}
