class AppConfig {
  AppConfig({
    required this.clientIdHeader,
    required this.redisHost,
  });

  final String redisHost;
  final String clientIdHeader;
}
