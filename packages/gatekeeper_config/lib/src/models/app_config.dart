import 'redis_config.dart';
import 'logging_config.dart';
import 'subdomain_config.dart';

/// Main application configuration container.
class AppConfig {
  AppConfig({
    required this.redis,
    required this.subdomains,
    required this.logging,
    required this.domain,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final redisJson = json['redis'] as Map<String, dynamic>;
    final subdomainsJson = json['subdomains'] as Map<String, dynamic>;
    final loggingJson = json['logging'] as Map<String, dynamic>;

    final redis = RedisConfig.fromJson(redisJson);

    final subdomains = <String, SubdomainConfig>{};
    for (final entry in subdomainsJson.entries) {
      subdomains[entry.key] = SubdomainConfig.fromJson(
        entry.value as Map<String, dynamic>,
      );
    }

    final logging = LoggingConfig.fromJson(loggingJson);

    final domain = json['domain'] as String;

    return AppConfig(
      redis: redis,
      subdomains: subdomains,
      logging: logging,
      domain: domain,
    );
  }

  final RedisConfig redis;
  final Map<String, SubdomainConfig> subdomains;
  final LoggingConfig logging;
  final String domain;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'redis': redis.toJson(),
      'subdomains': subdomains.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'logging': logging.toJson(),
      'domain': domain,
    };

    return json;
  }
}
