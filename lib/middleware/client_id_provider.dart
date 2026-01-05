import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/middleware/cookie_provider.dart';
import 'package:gatekeeper/util/extensions.dart';

class ClientIdContext {
  const ClientIdContext({
    required this.clientId,
    required this.source,
  });

  final String? clientId;
  final String? source;

  bool get clientIdFound => clientId != null && source != null;
}

Middleware clientIdProvider() {
  return (handler) {
    return (context) async {
      var clientId = context.request.headers[headerRequestorId];
      var clientIdSource = 'header';
      if (clientId == null) {
        final cookieContext = context.read<CookieContext>();
        clientId = cookieContext['client_id'];
        clientIdSource = 'cookie';
      }

      final clientIdContext = ClientIdContext(
        clientId: clientId,
        source: clientId == null ? null : clientIdSource,
      );

      final contextWithProvider = context.provide<ClientIdContext>(
        () => clientIdContext,
      );

      return handler(contextWithProvider);
    };
  };
}
