class Subdomain {
  static String? fromUri(Uri uri) {
    return fromHost(uri.host);
  }

  static String? fromHost(String host) {
    final parts = host.split('.');
    if (parts.length > 1) {
      return parts.first;
    }
    return null;
  }
}
