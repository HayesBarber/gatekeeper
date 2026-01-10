import 'package:gatekeeper/config/logging_config.dart';
import 'package:gatekeeper/config/redis_config.dart';
import 'package:gatekeeper/config/subdomain_config.dart';

class AppConfig {
  AppConfig({
    required this.redis,
    required this.subdomains,
    required this.logging,
    this.domain,
  });

  final RedisConfig redis;
  final Map<String, SubdomainConfig> subdomains;
  final LoggingConfig logging;
  final String? domain;
}
