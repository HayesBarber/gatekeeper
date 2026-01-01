import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/constants/subdomains.dart';
import 'package:gatekeeper/util/subdomain.dart';

Middleware githubWebhook() {
  return (handler) {
    return (context) async {
      final subdomain = Subdomain.fromUri(context.request.uri);
      if (subdomain != github) {
        return handler(context);
      }
      final config = context.read<ConfigService>().config;
      final subdomainConfig = config.subdomains[subdomain];
      if (subdomainConfig == null || subdomainConfig.secret == null) {
        return handler(context);
      }
      return handler(context);
    };
  };
}
