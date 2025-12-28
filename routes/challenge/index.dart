import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
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
  final client = await redis.get(ns: Namespace.users, key: clientId);

  if (client == null) {
    return Response(
      statusCode: HttpStatus.unauthorized,
      body: 'Unauthorized',
    );
  }

  final challenge = ChallengeResponse.random();

  await redis.set(
    ns: Namespace.challenges,
    key: client,
    value: challenge.encode(),
  );

  return Response.json(
    body: challenge,
  );
}
