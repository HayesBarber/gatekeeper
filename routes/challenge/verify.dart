import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:gatekeeper/dto/challenge_verification_request.dart';
import 'package:gatekeeper/dto/challenge_verification_response.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
import 'package:gatekeeper/middleware/client_id_provider.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/types/signature_verifier.dart';
import 'package:gatekeeper/util/extensions.dart';

Future<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.post => _onPost(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _onPost(RequestContext context) async {
  final clientId = context.read<ClientIdContext>().clientId;

  if (clientId == null) {
    return Response(
      statusCode: HttpStatus.unauthorized,
    );
  }

  final eventBuilder = context.read<we.WideEvent>();
  final start = DateTime.now();

  final redis = context.read<RedisClientBase>();
  final publicKey = await redis.get(ns: Namespace.users, key: clientId);

  if (publicKey == null) {
    eventBuilder.challenge = we.ChallengeContext(
      operationDurationMs: DateTime.now().since(start),
      publicKeyPresent: false,
    );
    return Response(
      statusCode: HttpStatus.unauthorized,
    );
  }

  final challengeData = await redis.get(
    ns: Namespace.challenges,
    key: clientId,
  );
  if (challengeData == null) {
    eventBuilder.challenge = we.ChallengeContext(
      operationDurationMs: DateTime.now().since(start),
      publicKeyPresent: true,
      challengePresent: false,
    );
    return Response(
      statusCode: HttpStatus.notFound,
    );
  }

  final challenge = ChallengeResponse.decode(challengeData);
  final bodyString = await context.request.body();
  final request = ChallengeVerificationRequest.decode(bodyString);

  if (challenge.challengeId != request.challengeId) {
    eventBuilder.challenge = we.ChallengeContext(
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
    eventBuilder.challenge = we.ChallengeContext(
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
    eventBuilder.challenge = we.ChallengeContext(
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

  final apiKey = ChallengeVerificationResponse.random();

  await redis.set(
    ns: Namespace.apiKeys,
    key: clientId,
    value: apiKey.encode(),
  );

  eventBuilder.challenge = we.ChallengeContext(
    operationDurationMs: DateTime.now().since(start),
  );
  return Response.json(
    body: apiKey,
  );
}
