import 'dart:convert';

class ChallengeVerificationResponse {
  ChallengeVerificationResponse({
    required this.apiKey,
    required this.expiresAt,
  });

  factory ChallengeVerificationResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeVerificationResponse(
      apiKey: json['api_key'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  factory ChallengeVerificationResponse.decode(String json) =>
      ChallengeVerificationResponse.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

  /// Issued API key tied to this client
  final String apiKey;

  /// UTC timestamp when the api key expires
  final DateTime expiresAt;

  Map<String, dynamic> toJson() {
    return {
      'api_key': apiKey,
      'expires_at': expiresAt.toUtc().toIso8601String(),
    };
  }

  String encode() => jsonEncode(toJson());
}
