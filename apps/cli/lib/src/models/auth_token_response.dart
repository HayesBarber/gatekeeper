class AuthTokenResponse {
  AuthTokenResponse({
    required this.apiKey,
    required this.expiresAt,
  });

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return AuthTokenResponse(
      apiKey: json['auth_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  final String apiKey;
  final DateTime expiresAt;

  Map<String, dynamic> toJson() {
    return {
      'auth_token': apiKey,
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}
