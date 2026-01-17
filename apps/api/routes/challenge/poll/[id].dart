import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/middleware/cookie_provider.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/util/cookie_util.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';
import 'package:gatekeeper_dto/gatekeeper_dto.dart';

Future<Response> onRequest(
  RequestContext context,
  String id,
) async {
  return switch (context.request.method) {
    HttpMethod.get => _onGet(context, id),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _onGet(
  RequestContext context,
  String id,
) async {
  final cookieContext = context.read<CookieContext>();
  final sessionId = cookieContext['session_id'];

  if (sessionId == null) {
    return Response(statusCode: HttpStatus.unauthorized);
  }

  final redis = context.read<RedisClientBase>();

  final challengeData = await redis.get(
    ns: Namespace.challenges,
    key: id,
  );

  if (challengeData == null) {
    return Response(statusCode: HttpStatus.notFound);
  }

  final challenge = ChallengeResponse.decode(challengeData);

  if (challenge.expiresAt.isBefore(DateTime.now())) {
    return Response(statusCode: HttpStatus.badRequest);
  }

  if (challenge.sessionId != sessionId) {
    return Response(statusCode: HttpStatus.forbidden);
  }

  if (!challenge.isVerified) {
    return Response.json(
      body: {'status': 'pending'},
    );
  }

  if (challenge.isPolled) {
    return Response(
      statusCode: HttpStatus.gone,
    );
  }

  final config = context.read<ConfigService>();
  final polledChallenge = challenge.markAsPolled();
  await redis.set(
    ns: Namespace.challenges,
    key: id,
    value: polledChallenge.encode(),
    ttl: config.config.redis.challengesTtl,
  );

  final setCookieHeader = CookieUtil.buildSetCookieHeader(
    'auth_token',
    challenge.authToken!,
    path: '/',
    domain: config.config.domain,
  );

  return Response.json(
    body: {'status': 'approved'},
    headers: {
      HttpHeaders.setCookieHeader: setCookieHeader,
    },
  );
}
