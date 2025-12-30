import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/dto/challenge_verification_response.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/util/subdomain.dart';

Middleware subdomainGatekeeper() {
  return (handler) {
    return (context) async {
      final config = context.read<ConfigService>().config;
      final subdomain = Subdomain.fromUri(context.request.uri);
      if (!config.subdomains.containsKey(subdomain)) {
        return handler(context);
      }

      final clientId = context.request.headers[headerRequestorId];
      if (clientId == null) {
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

      final apiKey = context.request.headers[headerApiKey];
      if (apiKey == null) {
        return Response(
          statusCode: HttpStatus.forbidden,
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

      return handler(context);
    };
  };
}
