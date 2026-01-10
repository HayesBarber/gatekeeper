import 'dart:io';

import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/constants/subdomains.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
import 'package:gatekeeper/middleware/subdomain_provider.dart';
import 'package:gatekeeper/util/extensions.dart';
import 'package:gatekeeper/util/forward_to_upstream.dart';

Middleware githubWebhook() {
  return (handler) {
    return (context) async {
      final subdomainContext = context.read<SubdomainContext>();
      if (subdomainContext.subdomain != github) {
        return handler(context);
      }

      if (!subdomainContext.hasConfig ||
          subdomainContext.config!.secret == null) {
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
        secret: subdomainContext.config!.secret!,
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

      final upstreamUrl = Uri.parse(subdomainContext.config!.url);

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
