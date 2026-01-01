class SubdomainConfig {
  const SubdomainConfig({
    required this.url,
    this.blacklistedPaths,
    this.secret,
  });

  final String url;
  final Map<String, List<String>>? blacklistedPaths;
  final String? secret;

  List<String> getBlacklistedPathsForMethod(String method) {
    return blacklistedPaths?[method] ?? [];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubdomainConfig &&
        other.url == url &&
        other.secret == secret &&
        _mapEquals(other.blacklistedPaths, blacklistedPaths);
  }

  @override
  int get hashCode => Object.hash(url, secret, _mapHash(blacklistedPaths));

  bool _mapEquals(Map<String, List<String>>? a, Map<String, List<String>>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final listA = a[key];
      final listB = b[key];
      if (listA?.length != listB?.length) return false;
      if (listA == null || listB == null) return false;
      for (var i = 0; i < listA.length; i++) {
        if (listA[i] != listB[i]) return false;
      }
    }
    return true;
  }

  int _mapHash(Map<String, List<String>>? map) {
    if (map == null) return 0;
    var hash = 0;
    for (final entry in map.entries) {
      hash = Object.hash(hash, entry.key);
      for (final item in entry.value) {
        hash = Object.hash(hash, item);
      }
    }
    return hash;
  }
}
