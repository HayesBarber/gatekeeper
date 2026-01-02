import 'dart:io';

import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/constants/subdomains.dart';
import 'package:gatekeeper/util/forward_to_upstream.dart';
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

      final signature = context.request.headers[hubSignature];
      if (signature == null) {
        return Response(
          statusCode: HttpStatus.unauthorized,
        );
      }

      final body = await context.request.body();
      final verified = WebhookVerifier.verifyGitHubWebhook(
        payload: body,
        signature: signature,
        secret: subdomainConfig.secret!,
      );
      if (!verified) {
        return Response(
          statusCode: HttpStatus.unauthorized,
        );
      }

      final upstreamUrl = Uri.parse(subdomainConfig.url);

      final forward = context.read<Forward>();

      return forward.toUpstream(
        context.request,
        upstreamUrl,
        body: body,
      );
    };
  };
}
