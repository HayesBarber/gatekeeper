import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/util/subdomain.dart';

Middleware subdomainGatekeeper() {
  return (handler) {
    return (context) async {
      final config = context.read<ConfigService>().config;
      final subdomain = Subdomain.fromUri(context.request.uri);
      if (config.subdomains.containsKey(subdomain)) {
        return Response(
          statusCode: 403,
          body: 'Subdomain not allowed',
        );
      }

      return handler(context);
    };
  };
}
