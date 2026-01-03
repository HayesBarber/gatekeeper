import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/config/subdomain_context.dart';

Middleware subdomainProvider() {
  return (handler) {
    return (context) async {
      final config = context.read<ConfigService>().config;
      final subdomainContext = SubdomainContext.fromUri(
        context.request.uri,
        config.subdomains,
      );

      final contextWithProvider = context.provide<SubdomainContext>(
        () => subdomainContext,
      );

      return handler(contextWithProvider);
    };
  };
}
