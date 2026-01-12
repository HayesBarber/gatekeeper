import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/middleware/subdomain_provider.dart';
import 'package:gatekeeper/util/auth_token_validator.dart';
import 'package:gatekeeper/util/extensions.dart';
import 'package:gatekeeper/util/forward_to_upstream.dart';
import 'package:gatekeeper/util/path_matcher.dart';
import 'package:gatekeeper/util/request_util.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';
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

      final blacklistedPaths = subdomainContext
              .config!.blacklistedPaths?[context.request.method.value] ??
          [];

      final pathBlacklisted = blacklistedPaths.isNotEmpty &&
          PathMatcher.isPathBlacklisted(
            blacklistedPaths,
            context.request.uri.path,
          );

      if (pathBlacklisted) {
        eventBuilder.authentication = gc.AuthenticationContext(
          authDurationMs: DateTime.now().since(start),
          pathBlacklisted: true,
        );
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

      final validationResult =
          await AuthTokenValidator.validateAuthTokenContext(
        context: context,
      );

      if (!validationResult.isValid) {
        final requestUtil = context.read<RequestUtil>();
        if (requestUtil.isBrowserRequest(context.request)) {
          final config = context.read<ConfigService>();
          return Response(
            statusCode: HttpStatus.temporaryRedirect,
            headers: {
              HttpHeaders.locationHeader: context.request.uri.replace(
                host: config.config.domain,
                path: '/index.html',
              ),
            },
          );
        }
        return validationResult.errorResponse!;
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
