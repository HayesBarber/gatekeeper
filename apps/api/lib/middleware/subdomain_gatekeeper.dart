import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/middleware/auth_token_provider.dart';
import 'package:gatekeeper/middleware/subdomain_provider.dart';
import 'package:gatekeeper/util/auth_token_validator.dart';
import 'package:gatekeeper/util/extensions.dart';
import 'package:gatekeeper/util/forward_to_upstream.dart';
import 'package:gatekeeper/util/path_matcher.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart' as gc;

Middleware subdomainGatekeeper() {
  return (handler) {
    return (context) async {
      final subdomainContext = context.read<SubdomainContext>();
      if (!subdomainContext.isValid) {
        return handler(context);
      }

      final eventBuilder = context.read<gc.WideEvent>();
      final start = DateTime.now();

      final validationResult =
          await AuthTokenValidator.validateAuthTokenContext(
        context: context,
      );

      if (!validationResult.isValid) {
        return validationResult.errorResponse!;
      }

      final authTokenSource = context.read<AuthTokenContext>().source!;

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
        eventBuilder.authentication = gc.AuthenticationContext(
          authDurationMs: DateTime.now().since(start),
          authTokenPresent: true,
          authTokenSource: authTokenSource,
          authTokenStored: true,
          authTokenValid: true,
          keyExpired: true,
          pathBlacklisted: true,
        );
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

      final upstreamUrl = Uri.parse(subdomainContext.config!.url);

      final forward = context.read<Forward>();

      eventBuilder.authentication = gc.AuthenticationContext(
        authDurationMs: DateTime.now().since(start),
      );
      return forward.toUpstream(
        context,
        upstreamUrl,
      );
    };
  };
}
