import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/dto/challenge_collection.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
import 'package:gatekeeper/middleware/client_id_provider.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/util/api_key_validator.dart';
import 'package:gatekeeper/util/challenge_helper.dart';
import 'package:gatekeeper/util/extensions.dart';

Future<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.get => _onGet(context),
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

  final challenge = ChallengeResponse.random();

  final collection =
      await ChallengeHelper.getChallengeCollection(redis, clientId) ??
          ChallengeCollection.empty()
        ..addChallenge(challenge);

  await ChallengeHelper.saveChallengeCollection(redis, clientId, collection);

  eventBuilder.challenge = we.ChallengeContext(
    operationDurationMs: DateTime.now().since(start),
  );
  return Response.json(
    body: challenge,
  );
}

Future<Response> _onGet(RequestContext context) async {
  final clientId = context.read<ClientIdContext>().clientId;

  if (clientId == null) {
    return Response(statusCode: HttpStatus.unauthorized);
  }

  final validationResult =
      await ApiKeyValidator.validateApiKeyContext(context: context);
  if (!validationResult.isValid) {
    return validationResult.errorResponse!;
  }

  final redis = context.read<RedisClientBase>();
  final collection =
      await ChallengeHelper.getChallengeCollection(redis, clientId);
  if (collection == null) {
    return Response.json(body: []);
  }

  final now = DateTime.now().toUtc();
  final activeChallenges = collection.challenges.values
      .where(
        (challenge) =>
            !challenge.isVerified && !challenge.expiresAt.isBefore(now),
      )
      .map(
        (challenge) => {
          'challenge_id': challenge.challengeId,
          'challenge': challenge.challenge,
          'expires_at': challenge.expiresAt.toUtc().toIso8601String(),
          'challenge_code': challenge.challengeCode,
        },
      )
      .toList();

  return Response.json(body: activeChallenges);
}
