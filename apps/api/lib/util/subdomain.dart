class Subdomain {
  static String? fromUri(Uri uri) {
    return fromHost(uri.host);
  }

  static String? fromHost(String host) {
    final parts = host.split('.');
    if (parts.length > 2) {
      return parts.sublist(0, parts.length - 2).join('.');
    }
    return null;
  }
}
