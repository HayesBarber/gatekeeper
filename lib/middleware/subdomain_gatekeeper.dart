import 'dart:io';

import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/dto/challenge_verification_response.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
import 'package:gatekeeper/middleware/api_key_provider.dart';
import 'package:gatekeeper/middleware/subdomain_provider.dart';
import 'package:gatekeeper/redis/redis_client.dart';
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

      final clientId = context.request.headers[headerRequestorId];
      if (clientId == null) {
        return Response(
          statusCode: HttpStatus.unauthorized,
        );
      }

      final eventBuilder = context.read<we.WideEvent>();
      final start = DateTime.now();

      final apiKeyContext = context.read<ApiKeyContext>();
      if (!apiKeyContext.apiKeyFound) {
        eventBuilder.authentication = we.AuthenticationContext(
          authDurationMs: DateTime.now().since(start),
          apiKeyPresent: false,
        );
        return Response(
          statusCode: HttpStatus.unauthorized,
        );
      }

      final apiKey = apiKeyContext.apiKey!;
      final apiKeySource = apiKeyContext.source!;

      final redis = context.read<RedisClientBase>();
      final storedApiKeyData = await redis.get(
        ns: Namespace.apiKeys,
        key: clientId,
      );
      if (storedApiKeyData == null) {
        eventBuilder.authentication = we.AuthenticationContext(
          authDurationMs: DateTime.now().since(start),
          apiKeyPresent: true,
          apiKeySource: apiKeySource,
          apiKeyStored: false,
        );
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

      final storedApiKey = ChallengeVerificationResponse.decode(
        storedApiKeyData,
      );

      if (!CryptoUtils.constantTimeCompare(apiKey, storedApiKey.apiKey)) {
        eventBuilder.authentication = we.AuthenticationContext(
          authDurationMs: DateTime.now().since(start),
          apiKeyPresent: true,
          apiKeySource: apiKeySource,
          apiKeyStored: true,
          apiKeyValid: false,
        );
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

      final keyExpired = storedApiKey.expiresAt.isBefore(DateTime.now());
      if (keyExpired) {
        eventBuilder.authentication = we.AuthenticationContext(
          authDurationMs: DateTime.now().since(start),
          apiKeyPresent: true,
          apiKeySource: apiKeySource,
          apiKeyStored: true,
          apiKeyValid: true,
          keyExpired: true,
        );
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

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
