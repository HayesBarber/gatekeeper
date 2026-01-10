import 'redis_config.dart';
import 'logging_config.dart';
import 'subdomain_config.dart';

/// Main application configuration container.
class AppConfig {
  final RedisConfig redis;
  final Map<String, SubdomainConfig> subdomains;
  final LoggingConfig logging;

  AppConfig({
    required this.redis,
    required this.subdomains,
    required this.logging,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final redisJson = json['redis'] as Map<String, dynamic>;
    final subdomainsJson = json['subdomains'] as Map<String, dynamic>;
    final loggingJson = json['logging'] as Map<String, dynamic>;

    final redis = RedisConfig.fromJson({
      ...redisJson,
      'challenges': redisJson['ttl']['challenges'],
      'auth_tokens': redisJson['ttl']['auth_tokens'],
    });

    final subdomains = <String, SubdomainConfig>{};
    for (final entry in subdomainsJson.entries) {
      subdomains[entry.key] = SubdomainConfig.fromJson(
        entry.value as Map<String, dynamic>,
      );
    }

    final logging = LoggingConfig.fromJson(loggingJson);

    return AppConfig(redis: redis, subdomains: subdomains, logging: logging);
  }

  Map<String, dynamic> toJson() {
    return {
      'redis': redis.toJson(),
      'subdomains': subdomains.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'logging': logging.toJson(),
    };
  }
}
