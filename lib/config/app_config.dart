class AppConfig {
  AppConfig({
    required this.clientIdHeader,
    required this.redisHost,
    required this.subdomainUpstreams,
  });

  final String redisHost;
  final String clientIdHeader;
  final Map<String, String> subdomainUpstreams;
}
