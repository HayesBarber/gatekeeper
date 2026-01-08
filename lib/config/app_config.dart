import 'package:gatekeeper/config/logging_config.dart';
import 'package:gatekeeper/config/subdomain_config.dart';

class AppConfig {
  AppConfig({
    required this.redisHost,
    required this.subdomains,
    required this.logging,
    this.domain,
  });

  final String redisHost;
  final Map<String, SubdomainConfig> subdomains;
  final LoggingConfig logging;
  final String? domain;
}
