import 'package:gatekeeper/config/subdomain_config.dart';

class AppConfig {
  AppConfig({
    required this.clientIdHeader,
    required this.redisHost,
    required this.subdomains,
  });

  final String redisHost;
  final String clientIdHeader;
  final Map<String, SubdomainConfig> subdomains;
}
