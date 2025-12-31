import 'package:gatekeeper/config/subdomain_config.dart';

class AppConfig {
  AppConfig({
    required this.redisHost,
    required this.subdomains,
  });

  final String redisHost;
  final Map<String, SubdomainConfig> subdomains;
}
