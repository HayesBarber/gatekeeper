import 'dart:io';

import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/middleware/subdomain_provider.dart';
import 'package:gatekeeper/util/extensions.dart';
import 'package:gatekeeper/util/forward_to_upstream.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart' as gc;

Middleware githubWebhook() {
  return (handler) {
    return (context) async {
      final subdomainContext = context.read<SubdomainContext>();
      if (subdomainContext.subdomain != gc.github) {
        return handler(context);
      }

      if (!subdomainContext.hasConfig ||
          subdomainContext.config!.secret == null) {
        return handler(context);
      }

      final eventBuilder = context.read<gc.WideEvent>();
      final start = DateTime.now();

      final eventType = context.request.headers[gc.githubEvent];
      final deliveryId = context.request.headers[gc.githubDelivery];

      final signature = context.request.headers[gc.hubSignature];
      if (signature == null) {
        eventBuilder.webhook = gc.WebhookContext(
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
        secret: subdomainContext.config!.secret!,
      );
      if (!verified) {
        eventBuilder.webhook = gc.WebhookContext(
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

      final upstreamUrl = Uri.parse(subdomainContext.config!.url);

      final forward = context.read<Forward>();

      eventBuilder.webhook = gc.WebhookContext(
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
