import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/middleware/cookie_provider.dart';
import 'package:gatekeeper/util/extensions.dart';

class AuthTokenContext {
  const AuthTokenContext({
    required this.authToken,
    required this.source,
  });

  final String? authToken;
  final String? source;

  bool get authTokenFound => authToken != null && source != null;
}

Middleware authTokenProvider() {
  return (handler) {
    return (context) async {
      var authToken = context.request.headers.bearer();
      var authTokenSource = 'header';
      if (authToken == null) {
        final cookieContext = context.read<CookieContext>();
        authToken = cookieContext['auth_token'];
        authTokenSource = 'cookie';
      }

      final authTokenContext = AuthTokenContext(
        authToken: authToken,
        source: authToken == null ? null : authTokenSource,
      );

      final contextWithProvider = context.provide<AuthTokenContext>(
        () => authTokenContext,
      );

      return handler(contextWithProvider);
    };
  };
}
