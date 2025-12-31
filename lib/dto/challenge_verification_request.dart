import 'dart:convert';

class ChallengeVerificationRequest {
  ChallengeVerificationRequest({
    required this.challengeId,
    required this.signature,
  });

  factory ChallengeVerificationRequest.fromJson(Map<String, dynamic> json) {
    return ChallengeVerificationRequest(
      challengeId: json['challenge_id'] as String,
      signature: json['signature'] as String,
    );
  }

  factory ChallengeVerificationRequest.decode(String json) =>
      ChallengeVerificationRequest.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

  /// Unique identifier for the challenge
  final String challengeId;

  /// Base64-encoded signature over the challenge using client's private key
  final String signature;

  Map<String, dynamic> toJson() {
    return {
      'challenge_id': challengeId,
      'signature': signature,
    };
  }

  String encode() => jsonEncode(toJson());
}
