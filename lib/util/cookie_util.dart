import 'dart:io';

class CookieUtil {
  static String buildSetCookieHeader(
    String name,
    String value, {
    DateTime? expires,
    String? domain,
    String? path,
    int? maxAge,
    bool httpOnly = true,
    bool secure = true,
    String sameSite = 'Lax',
  }) {
    final cookieParts = <String>['$name=$value'];

    if (expires != null) {
      cookieParts.add('Expires=${_formatExpires(expires)}');
    }

    if (domain != null) {
      cookieParts.add('Domain=$domain');
    }

    if (path != null) {
      cookieParts.add('Path=$path');
    }

    if (maxAge != null) {
      cookieParts.add('Max-Age=$maxAge');
    }

    if (httpOnly) {
      cookieParts.add('HttpOnly');
    }

    if (secure) {
      cookieParts.add('Secure');
    }

    cookieParts.add('SameSite=$sameSite');

    return cookieParts.join('; ');
  }

  static String _formatExpires(DateTime expires) {
    return HttpDate.format(expires);
  }
}
