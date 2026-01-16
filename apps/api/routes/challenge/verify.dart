import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart' as gc;
import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';

Future<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.post => _onPost(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _onPost(RequestContext context) async {
  final bodyString = await context.request.body();
  final request = gc.ChallengeVerificationRequest.decode(bodyString);

  final redis = context.read<RedisClientBase>();
  final config = context.read<ConfigService>();
  final publicKey = await redis.get(
    ns: Namespace.devices,
    key: request.deviceId,
  );

  if (publicKey == null) {
    return Response(
      statusCode: HttpStatus.unauthorized,
    );
  }

  final challengeData = await redis.get(
    ns: Namespace.challenges,
    key: request.challengeId,
  );
  if (challengeData == null) {
    return Response(
      statusCode: HttpStatus.notFound,
    );
  }

  final challenge = gc.ChallengeResponse.decode(challengeData);

  if (challenge.challengeId != request.challengeId) {
    return Response(
      statusCode: HttpStatus.badRequest,
    );
  }

  if (challenge.expiresAt.isBefore(DateTime.now())) {
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
    return Response(
      statusCode: HttpStatus.forbidden,
    );
  }

  final authToken = gc.ChallengeVerificationResponse.random(
    ttl: config.config.redis.authTokensTtl,
  );
  final verifiedChallenge = challenge.markAsVerified(
    apiKey: authToken.authToken,
    pollingTtl: config.config.redis.challengesTtl,
  );

  await redis.set(
    ns: Namespace.challenges,
    key: verifiedChallenge.challengeId,
    value: verifiedChallenge.encode(),
    ttl: config.config.redis.challengesTtl,
  );

  await redis.set(
    ns: Namespace.authTokens,
    key: authToken.authToken,
    value: authToken.encode(),
    ttl: config.config.redis.authTokensTtl,
  );

  return Response.json(
    body: authToken,
  );
}
