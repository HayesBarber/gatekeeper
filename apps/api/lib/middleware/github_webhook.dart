import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/constants/constants.dart';
import 'package:gatekeeper/middleware/subdomain_provider.dart';
import 'package:gatekeeper/util/forward_to_upstream.dart';
import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';

Middleware githubWebhook() {
  return (handler) {
    return (context) async {
      final subdomainContext = context.read<SubdomainContext>();
      if (subdomainContext.subdomain != Constants.github) {
        return handler(context);
      }

      if (!subdomainContext.hasConfig ||
          subdomainContext.config!.secret == null) {
        return handler(context);
      }

      final signature = context.request.headers[Constants.hubSignature];
      if (signature == null) {
        return Response(
          statusCode: HttpStatus.unauthorized,
        );
      }

      final body = await context.request.body();
      final verified = WebhookVerifier.verifyGitHubWebhook(
        payload: body,
        signature: signature,
        secret: subdomainContext.config!.secret!,
      );
      if (!verified) {
        return Response(
          statusCode: HttpStatus.unauthorized,
        );
      }

      final upstreamUrl = Uri.parse(subdomainContext.config!.url);

      final forward = context.read<Forward>();

      return forward.toUpstream(
        context,
        upstreamUrl,
        body: body,
      );
    };
  };
}
