import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/dto/challenge_verification_response.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/util/forward_to_upstream.dart';
import 'package:gatekeeper/util/path_matcher.dart';
import 'package:gatekeeper/util/subdomain.dart';

Middleware subdomainGatekeeper() {
  return (handler) {
    return (context) async {
      final config = context.read<ConfigService>().config;
      final subdomain = Subdomain.fromUri(context.request.uri);
      final subdomainConfig = config.subdomains[subdomain];
      if (subdomain == null || subdomainConfig == null) {
        return handler(context);
      }

      final clientId = context.request.headers[headerRequestorId];
      if (clientId == null) {
        return Response(
          statusCode: HttpStatus.unauthorized,
        );
      }

      final apiKey =
          _extractBearerToken(context.request.headers[headerAuthorization]);
      if (apiKey == null) {
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
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

      final storedApiKey = ChallengeVerificationResponse.decode(
        storedApiKeyData,
      );

      if (apiKey != storedApiKey.apiKey) {
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

      if (storedApiKey.expiresAt.isBefore(DateTime.now())) {
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

      final blacklistedPaths = subdomainConfig.getBlacklistedPathsForMethod(
        context.request.method.value,
      );
      if (blacklistedPaths.isNotEmpty) {
        final requestPath = context.request.uri.path;
        if (PathMatcher.isPathBlacklisted(blacklistedPaths, requestPath)) {
          return Response(
            statusCode: HttpStatus.forbidden,
          );
        }
      }

      final upstreamUrl = Uri.parse(subdomainConfig.url);

      return forwardToUpstream(
        context.request,
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
