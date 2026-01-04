import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/util/extensions.dart';

class ApiKeyContext {
  const ApiKeyContext({
    required this.apiKey,
    required this.source,
  });

  final String? apiKey;
  final String? source;

  bool get apiKeyFound => apiKey != null && source != null;
}

Middleware apiKeyProvider() {
  return (handler) {
    return (context) async {
      var apiKey = context.request.headers.bearer();
      var apiKeySource = 'header';
      if (apiKey == null) {
        final cookies = context.request.headers.cookies();
        apiKey = cookies?['api_key'];
        apiKeySource = 'cookie';
      }

      final apiKeyContext = ApiKeyContext(
        apiKey: apiKey,
        source: apiKey == null ? null : apiKeySource,
      );

      final contextWithProvider = context.provide<ApiKeyContext>(
        () => apiKeyContext,
      );

      return handler(contextWithProvider);
    };
  };
}
