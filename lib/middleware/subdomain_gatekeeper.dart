import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
import 'package:gatekeeper/middleware/api_key_provider.dart';
import 'package:gatekeeper/middleware/client_id_provider.dart';
import 'package:gatekeeper/middleware/subdomain_provider.dart';
import 'package:gatekeeper/util/api_key_validator.dart';
import 'package:gatekeeper/util/extensions.dart';
import 'package:gatekeeper/util/forward_to_upstream.dart';
import 'package:gatekeeper/util/path_matcher.dart';

Middleware subdomainGatekeeper() {
  return (handler) {
    return (context) async {
      final subdomainContext = context.read<SubdomainContext>();
      if (!subdomainContext.isValid) {
        return handler(context);
      }

      final clientId = context.read<ClientIdContext>().clientId;
      if (clientId == null) {
        return Response(
          statusCode: HttpStatus.unauthorized,
        );
      }

      final eventBuilder = context.read<we.WideEvent>();
      final start = DateTime.now();

      final validationResult = await ApiKeyValidator.validateApiKeyContext(
        context: context,
      );

      if (!validationResult.isValid) {
        return validationResult.errorResponse!;
      }

      final apiKeySource = context.read<ApiKeyContext>().source!;

      final blacklistedPaths =
          subdomainContext.config!.getBlacklistedPathsForMethod(
        context.request.method.value,
      );
      final pathBlacklisted = blacklistedPaths.isNotEmpty &&
          PathMatcher.isPathBlacklisted(
            blacklistedPaths,
            context.request.uri.path,
          );

      if (pathBlacklisted) {
        eventBuilder.authentication = we.AuthenticationContext(
          authDurationMs: DateTime.now().since(start),
          apiKeyPresent: true,
          apiKeySource: apiKeySource,
          apiKeyStored: true,
          apiKeyValid: true,
          keyExpired: true,
          pathBlacklisted: true,
        );
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

      final upstreamUrl = Uri.parse(subdomainContext.config!.url);

      final forward = context.read<Forward>();

      eventBuilder.authentication = we.AuthenticationContext(
        authDurationMs: DateTime.now().since(start),
      );
      return forward.toUpstream(
        context,
        upstreamUrl,
      );
    };
  };
}
