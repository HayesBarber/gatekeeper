/// Configuration for Redis connection and TTL settings.
class RedisConfig {
  final String host;
  final Duration challengesTtl;
  final Duration authTokensTtl;

  RedisConfig({
    required this.host,
    required this.challengesTtl,
    required this.authTokensTtl,
  });

  factory RedisConfig.fromJson(Map<String, dynamic> json) {
    return RedisConfig(
      host: json['host'] as String,
      challengesTtl: _parseDuration(json['challenges'] as String),
      authTokensTtl: _parseDuration(json['auth_tokens'] as String),
    );
  }

  static Duration _parseDuration(String durationStr) {
    final regex = RegExp(r'^(\d+)([smhd])?$');
    final match = regex.firstMatch(durationStr.trim());

    if (match == null) {
      throw FormatException('Invalid duration format: $durationStr');
    }

    final value = int.parse(match.group(1)!);
    final unit = match.group(2) ?? 's';

    switch (unit) {
      case 's':
        return Duration(seconds: value);
      case 'm':
        return Duration(minutes: value);
      case 'h':
        return Duration(hours: value);
      case 'd':
        return Duration(days: value);
      default:
        throw FormatException('Unsupported unit: $unit');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'challengesTtl': challengesTtl.inSeconds,
      'authTokensTtl': authTokensTtl.inSeconds,
    };
  }
}
