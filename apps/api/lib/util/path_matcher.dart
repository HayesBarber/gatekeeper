class PathMatcher {
  static bool matches(String pattern, String path) {
    if (pattern == '*') return true;
    if (!pattern.contains('*') && !pattern.contains('?')) {
      return pattern == path;
    }

    final regexPattern = pattern.replaceAll('*', '.*').replaceAll('?', '.');
    final regex = RegExp('^$regexPattern\$');
    return regex.hasMatch(path);
  }

  static bool isPathBlacklisted(
    List<String> patterns,
    String path,
  ) {
    for (final pattern in patterns) {
      if (matches(pattern, path)) {
        return true;
      }
    }
    return false;
  }
}
