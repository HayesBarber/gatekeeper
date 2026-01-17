import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/util/auth_token_validator.dart';
import 'package:gatekeeper/util/cookie_util.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';
import 'package:gatekeeper_dto/gatekeeper_dto.dart';

Future<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.get => _onGet(context),
    HttpMethod.post => _onPost(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _onPost(RequestContext context) async {
  final redis = context.read<RedisClientBase>();
  final config = context.read<ConfigService>();

  final challenge =
      ChallengeResponse.random(ttl: config.config.redis.challengesTtl);

  await redis.set(
    ns: Namespace.challenges,
    key: challenge.challengeId,
    value: challenge.encode(),
    ttl: config.config.redis.challengesTtl,
  );

  final setCookieHeader = CookieUtil.buildSetCookieHeader(
    'session_id',
    challenge.sessionId,
    path: '/',
  );

  return Response.json(
    body: challenge.toPublicJson(),
    headers: {
      HttpHeaders.setCookieHeader: setCookieHeader,
    },
  );
}

Future<Response> _onGet(RequestContext context) async {
  final validationResult = await AuthTokenValidator.validateAuthTokenContext(
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
        (challenge) => challenge.toPublicJson(),
      )
      .toList();

  return Response.json(body: activeChallenges);
}
