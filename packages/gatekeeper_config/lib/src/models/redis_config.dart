/// Configuration for Redis connection and TTL settings.
class RedisConfig {
  RedisConfig({
    required this.host,
    required this.challengesTtl,
    required this.authTokensTtl,
  });

  factory RedisConfig.fromJson(Map<String, dynamic> json) {
    // Handle both flat format (challenges, auth_tokens) and nested format (ttl.challenges, ttl.auth_tokens)
    String challengesStr;
    String authTokensStr;

    final ttlJson = json['ttl'] as Map<String, dynamic>;
    challengesStr = ttlJson['challenges'] as String;
    authTokensStr = ttlJson['auth_tokens'] as String;

    return RedisConfig(
      host: json['host'] as String,
      challengesTtl: _parseDuration(challengesStr),
      authTokensTtl: _parseDuration(authTokensStr),
    );
  }

  final String host;
  final Duration challengesTtl;
  final Duration authTokensTtl;

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
      'ttl': {
        'challenges': _durationToString(challengesTtl),
        'auth_tokens': _durationToString(authTokensTtl),
      },
    };
  }

  String _durationToString(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds % 60 == 0) {
      final minutes = seconds ~/ 60;
      if (minutes % 60 == 0) {
        final hours = minutes ~/ 60;
        if (hours % 24 == 0) {
          final days = hours ~/ 24;
          return '${days}d';
        }
        return '${hours}h';
      }
      return '${minutes}m';
    }
    return '${seconds}s';
  }
}
