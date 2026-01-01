import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/constants/subdomains.dart';
import 'package:gatekeeper/util/subdomain.dart';

Middleware githubWebhook() {
  return (handler) {
    return (context) async {
      final subdomain = Subdomain.fromUri(context.request.uri);
      if (subdomain != github) {
        return handler(context);
      }
      return handler(context);
    };
  };
}
