import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/util/subdomain.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';

class SubdomainContext {
  const SubdomainContext({
    required this.subdomain,
    required this.config,
  });

  factory SubdomainContext.fromUri(
    Uri uri,
    Map<String, SubdomainConfig> configMap,
  ) {
    final subdomain = Subdomain.fromUri(uri);
    final config = configMap[subdomain];
    return SubdomainContext(
      subdomain: subdomain,
      config: config,
    );
  }

  final String? subdomain;
  final SubdomainConfig? config;

  bool get hasSubdomain => subdomain != null;
  bool get hasConfig => config != null;
  bool get isValid => hasSubdomain && hasConfig;
}

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
