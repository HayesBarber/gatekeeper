class AuthTokenResponse {
  AuthTokenResponse({
    required this.authToken,
    required this.expiresAt,
  });

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return AuthTokenResponse(
      authToken: json['auth_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  final String authToken;
  final DateTime expiresAt;

  Map<String, dynamic> toJson() {
    return {
      'auth_token': authToken,
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}
