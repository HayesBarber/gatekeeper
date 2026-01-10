class RedisConfig {
  const RedisConfig({
    required this.host,
    required this.challengesTtl,
    required this.apiKeysTtl,
  });

  const RedisConfig.defaultConfig()
      : host = '127.0.0.1',
        challengesTtl = const Duration(seconds: 30),
        apiKeysTtl = const Duration(minutes: 5);

  final String host;
  final Duration challengesTtl;
  final Duration apiKeysTtl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RedisConfig &&
          runtimeType == other.runtimeType &&
          host == other.host &&
          challengesTtl == other.challengesTtl &&
          apiKeysTtl == other.apiKeysTtl;

  @override
  int get hashCode =>
      host.hashCode ^ challengesTtl.hashCode ^ apiKeysTtl.hashCode;
}
