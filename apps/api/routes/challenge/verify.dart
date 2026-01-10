import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/types/signature_verifier.dart';
import 'package:gatekeeper/util/extensions.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart' as gc;

Future<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.post => _onPost(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _onPost(RequestContext context) async {
  final start = DateTime.now();
  final eventBuilder = context.read<gc.WideEvent>();
  final bodyString = await context.request.body();
  final request = gc.ChallengeVerificationRequest.decode(bodyString);

  final redis = context.read<RedisClientBase>();
  final config = context.read<ConfigService>();
  final publicKey = await redis.get(
    ns: Namespace.devices,
    key: request.deviceId,
  );

  if (publicKey == null) {
    eventBuilder.challenge = gc.ChallengeContext(
      operationDurationMs: DateTime.now().since(start),
      publicKeyPresent: false,
    );
    return Response(
      statusCode: HttpStatus.unauthorized,
    );
  }

  final challengeData = await redis.get(
    ns: Namespace.challenges,
    key: request.challengeId,
  );
  if (challengeData == null) {
    eventBuilder.challenge = gc.ChallengeContext(
      operationDurationMs: DateTime.now().since(start),
      publicKeyPresent: true,
      challengePresent: false,
    );
    return Response(
      statusCode: HttpStatus.notFound,
    );
  }

  final challenge = gc.ChallengeResponse.decode(challengeData);

  if (challenge.challengeId != request.challengeId) {
    eventBuilder.challenge = gc.ChallengeContext(
      operationDurationMs: DateTime.now().since(start),
      publicKeyPresent: true,
      challengePresent: true,
      challengeId: challenge.challengeId,
      challengeIdMismatch: true,
    );
    return Response(
      statusCode: HttpStatus.badRequest,
    );
  }

  if (challenge.expiresAt.isBefore(DateTime.now())) {
    eventBuilder.challenge = gc.ChallengeContext(
      operationDurationMs: DateTime.now().since(start),
      publicKeyPresent: true,
      challengePresent: true,
      challengeId: challenge.challengeId,
      challengeIdMismatch: false,
      challengeExpired: true,
    );
    return Response(
      statusCode: HttpStatus.badRequest,
    );
  }

  final verify = context.read<SignatureVerifier>();

  final isValid = verify(
    challenge.challenge,
    request.signature,
    publicKey,
  );

  if (!isValid) {
    eventBuilder.challenge = gc.ChallengeContext(
      operationDurationMs: DateTime.now().since(start),
      publicKeyPresent: true,
      challengePresent: true,
      challengeId: challenge.challengeId,
      challengeIdMismatch: false,
      challengeExpired: false,
      signatureValid: false,
    );
    return Response(
      statusCode: HttpStatus.forbidden,
    );
  }

  final apiKey = gc.ChallengeVerificationResponse.random(
    ttl: config.config.redis.apiKeysTtl,
  );
  final verifiedChallenge = challenge.markAsVerified(
    apiKey: apiKey.apiKey,
    pollingTtl: config.config.redis.challengesTtl,
  );

  await redis.set(
    ns: Namespace.challenges,
    key: verifiedChallenge.challengeId,
    value: verifiedChallenge.encode(),
    ttl: config.config.redis.challengesTtl,
  );

  await redis.set(
    ns: Namespace.apiKeys,
    key: apiKey.apiKey,
    value: apiKey.encode(),
    ttl: config.config.redis.apiKeysTtl,
  );

  eventBuilder.challenge = gc.ChallengeContext(
    operationDurationMs: DateTime.now().since(start),
  );
  return Response.json(
    body: apiKey,
  );
}
