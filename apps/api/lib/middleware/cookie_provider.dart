import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/util/extensions.dart';

class CookieContext {
  const CookieContext(this.cookies);

  final Map<String, String>? cookies;

  String? operator [](String key) => cookies?[key];
  bool contains(String key) => cookies?.containsKey(key) ?? false;
}

Middleware cookieProvider() {
  return (handler) {
    return (context) async {
      final cookies = context.request.headers.cookies();
      final cookieContext = CookieContext(cookies);

      final contextWithProvider = context.provide<CookieContext>(
        () => cookieContext,
      );

      return handler(contextWithProvider);
    };
  };
}
