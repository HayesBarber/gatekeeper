/// Result of the init operation.
class InitResult {
  InitResult({
    required this.configPath,
    required this.keypairPath,
    required this.subdomains,
  });

  final String configPath;
  final String keypairPath;
  final List<String> subdomains;
}
