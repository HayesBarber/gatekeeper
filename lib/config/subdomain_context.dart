import 'package:gatekeeper/config/subdomain_config.dart';
import 'package:gatekeeper/util/subdomain.dart';

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
