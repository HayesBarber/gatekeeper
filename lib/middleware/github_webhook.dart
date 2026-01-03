import 'dart:io';

import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/constants/subdomains.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
import 'package:gatekeeper/util/extensions.dart';
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

      final eventBuilder = context.read<we.WideEvent>();
      final start = DateTime.now();

      final eventType = context.request.headers[githubEvent];
      final deliveryId = context.request.headers[githubDelivery];

      final signature = context.request.headers[hubSignature];
      if (signature == null) {
        eventBuilder.webhook = we.WebhookContext(
          verificationDurationMs: DateTime.now().since(start),
          eventType: eventType,
          deliveryId: deliveryId,
          signaturePresent: false,
        );
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
        eventBuilder.webhook = we.WebhookContext(
          verificationDurationMs: DateTime.now().since(start),
          eventType: eventType,
          deliveryId: deliveryId,
          signaturePresent: true,
          signatureValid: false,
        );
        return Response(
          statusCode: HttpStatus.unauthorized,
        );
      }

      final upstreamUrl = Uri.parse(subdomainConfig.url);

      final forward = context.read<Forward>();

      eventBuilder.webhook = we.WebhookContext(
        verificationDurationMs: DateTime.now().since(start),
        eventType: eventType,
        deliveryId: deliveryId,
      );
      return forward.toUpstream(
        context,
        upstreamUrl,
        body: body,
      );
    };
  };
}
