import 'package:gatekeeper_config/gatekeeper_config.dart';

/// Configuration for Redis connection and TTL settings.
class RedisConfig {
  RedisConfig({
    required this.host,
    required this.challengesTtl,
    required this.authTokensTtl,
  });

  factory RedisConfig.fromJson(Map<String, dynamic> json) {
    final ttlJson = json['ttl'] as Map<String, dynamic>;
    String challengesStr = ttlJson['challenges'] as String;
    String authTokensStr = ttlJson['auth_tokens'] as String;

    return RedisConfig(
      host: json['host'] as String,
      challengesTtl: TtlParser.parse(challengesStr),
      authTokensTtl: TtlParser.parse(authTokensStr),
    );
  }

  final String host;
  final Duration challengesTtl;
  final Duration authTokensTtl;

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
