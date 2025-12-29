class SubdomainConfig {
  const SubdomainConfig({
    required this.url,
  });

  final String url;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubdomainConfig && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
