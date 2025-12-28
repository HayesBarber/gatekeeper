import 'dart:io';

import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:gatekeeper/dto/challenge_verification_request.dart';
import 'package:gatekeeper/dto/challenge_verification_response.dart';
import 'package:gatekeeper/redis/redis_client.dart';

Future<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.post => _onPost(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _onPost(RequestContext context) async {
  final headers = context.request.headers;
  final config = context.read<ConfigService>().config;
  final clientId = headers[config.clientIdHeader];

  if (clientId == null) {
    return Response(
      statusCode: HttpStatus.unauthorized,
      body: 'Unauthorized',
    );
  }

  final redis = context.read<RedisClientBase>();
  final publicKey = await redis.get(ns: Namespace.users, key: clientId);

  if (publicKey == null) {
    return Response(
      statusCode: HttpStatus.unauthorized,
      body: 'Unauthorized',
    );
  }

  final bodyString = await context.request.body();
  final request = ChallengeVerificationRequest.decode(bodyString);

  final challengeData = await redis.get(
    ns: Namespace.challenges,
    key: clientId,
  );
  if (challengeData == null) {
    return Response(
      statusCode: HttpStatus.notFound,
      body: 'No challenge found',
    );
  }

  final challenge = ChallengeResponse.decode(challengeData);

  if (challenge.challengeId != request.challengeId) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: 'Invalid challenge',
    );
  }

  if (challenge.expiresAt.isBefore(DateTime.now())) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: 'Challenge expired',
    );
  }

  final isValid = VerifySignature.verifySignature(
    challenge.challenge,
    request.signature,
    publicKey,
  );

  if (!isValid) {
    return Response(
      statusCode: HttpStatus.forbidden,
      body: 'Invalid signature',
    );
  }

  final apiKey = ChallengeVerificationResponse.random();

  await redis.set(
    ns: Namespace.apiKeys,
    key: clientId,
    value: apiKey.encode(),
  );

  return Response.json(
    body: apiKey,
  );
}
