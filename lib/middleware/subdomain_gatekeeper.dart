import 'dart:io';

import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/dto/challenge_verification_response.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
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

      final apiKey =
          _extractBearerToken(context.request.headers[headerAuthorization]);
      if (apiKey == null) {
        eventBuilder.authentication = we.AuthenticationContext(
          authDurationMs: DateTime.now().since(start),
          apiKeyHeaderPresent: false,
        );
        return Response(
          statusCode: HttpStatus.unauthorized,
        );
      }

      final redis = context.read<RedisClientBase>();
      final storedApiKeyData = await redis.get(
        ns: Namespace.apiKeys,
        key: clientId,
      );
      if (storedApiKeyData == null) {
        eventBuilder.authentication = we.AuthenticationContext(
          authDurationMs: DateTime.now().since(start),
          apiKeyHeaderPresent: true,
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
          apiKeyHeaderPresent: true,
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
          apiKeyHeaderPresent: true,
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
          apiKeyHeaderPresent: true,
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

String? _extractBearerToken(String? authHeader) {
  if (authHeader == null) return null;

  final parts = authHeader.trim().split(RegExp(r'\s+'));
  if (parts.length < 2 || parts[0].toLowerCase() != 'bearer') return null;

  final token = parts.sublist(1).join(' ').trim();
  return token.isEmpty ? null : token;
}
