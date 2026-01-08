import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/util/api_key_validator.dart';
import 'package:gatekeeper/util/cookie_util.dart';
import 'package:gatekeeper/util/extensions.dart';

Future<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.get => _onGet(context),
    HttpMethod.post => _onPost(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _onPost(RequestContext context) async {
  final start = DateTime.now();
  final eventBuilder = context.read<we.WideEvent>();

  final redis = context.read<RedisClientBase>();

  final challenge = ChallengeResponse.random();

  await redis.set(
    ns: Namespace.challenges,
    key: challenge.challengeId,
    value: challenge.encode(),
  );

  eventBuilder.challenge = we.ChallengeContext(
    operationDurationMs: DateTime.now().since(start),
    challengeId: challenge.challengeId,
  );

  final setCookieHeader = CookieUtil.buildSetCookieHeader(
    'session_id',
    challenge.sessionId,
    path: '/',
  );

  return Response.json(
    body: {
      'challenge_id': challenge.challengeId,
      'challenge': challenge.challenge,
      'expires_at': challenge.expiresAt.toUtc().toIso8601String(),
      'challenge_code': challenge.challengeCode,
    },
    headers: {
      headerSetCookie: setCookieHeader,
    },
  );
}

Future<Response> _onGet(RequestContext context) async {
  final validationResult = await ApiKeyValidator.validateApiKeyContext(
    context: context,
  );
  if (!validationResult.isValid) {
    return validationResult.errorResponse!;
  }

  final redis = context.read<RedisClientBase>();
  final collection = await redis.getAll(
    ns: Namespace.challenges,
    parser: ChallengeResponse.decode,
  );

  final now = DateTime.now().toUtc();
  final activeChallenges = collection
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
