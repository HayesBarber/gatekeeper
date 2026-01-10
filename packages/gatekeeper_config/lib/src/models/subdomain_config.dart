/// Configuration for a subdomain with URL, blacklist, and optional secret.
class SubdomainConfig {
  final String url;
  final Map<String, List<String>>? blacklistedPaths;
  final String? secret;

  SubdomainConfig({required this.url, this.blacklistedPaths, this.secret});

  factory SubdomainConfig.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>>? blacklistedPaths;

    if (json.containsKey('blacklist')) {
      final blacklistJson = json['blacklist'] as Map<String, dynamic>;
      blacklistedPaths = {};

      for (final entry in blacklistJson.entries) {
        final method = entry.key;
        final paths = (entry.value as List<dynamic>).cast<String>();
        blacklistedPaths[method] = paths;
      }
    }

    return SubdomainConfig(
      url: json['url'] as String,
      blacklistedPaths: blacklistedPaths,
      secret: json['secret'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'url': url};

    if (blacklistedPaths != null) {
      json['blacklist'] = blacklistedPaths;
    }

    if (secret != null) {
      json['secret'] = secret;
    }

    return json;
  }
}
