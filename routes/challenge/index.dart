import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/util/extensions.dart';

Future<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.post => _onPost(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _onPost(RequestContext context) async {
  final eventBuilder = context.read<we.WideEvent>();
  final start = DateTime.now();

  final redis = context.read<RedisClientBase>();

  final challenge = ChallengeResponse.random();

  await redis.set(
    ns: Namespace.challenges,
    key: challenge.challengeId,
    value: challenge.encode(),
  );

  eventBuilder.challenge = we.ChallengeContext(
    operationDurationMs: DateTime.now().since(start),
  );
  return Response.json(
    body: challenge,
  );
}
