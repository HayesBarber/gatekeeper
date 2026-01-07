import 'dart:convert';
import 'dart:io';

import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../../util/it_util.dart';
import '../../../util/test_env.dart';

void main() {
  group('GET /challenge/poll/[id]', () {
    late RedisClientBase redis;

    setUpAll(() async {
      redis = await ShorebirdRedisClient.connect(host: TestEnv.redisHost);
    });

    tearDown(() async {
      await redis.deleteAll(
        ns: Namespace.challenges,
      );
      await redis.deleteAll(
        ns: Namespace.apiKeys,
      );
    });

    tearDownAll(() async {
      await redis.close();
    });

    test('returns 405 for non-GET methods', () async {
      final methods = [
        (http.post, 'POST'),
        (http.put, 'PUT'),
        (http.patch, 'PATCH'),
        (http.delete, 'DELETE'),
      ];

      for (final record in methods) {
        final res = await record.$1(
          TestEnv.apiUri('/challenge/poll/invalid-id'),
        );
        expect(res.statusCode, equals(HttpStatus.methodNotAllowed));
      }
    });

    test('returns 401 when session_id cookie is missing', () async {
      // TODO: Implement test
    });

    test('returns 404 when challenge does not exist', () async {
      // TODO: Implement test
    });

    test('returns 400 when challenge is expired', () async {
      // TODO: Implement test
    });

    test('returns 403 when session ID does not match', () async {
      // TODO: Implement test
    });

    test('returns pending status when challenge is not verified', () async {
      // TODO: Implement test
    });

    test('returns 410 when challenge has already been polled', () async {
      // TODO: Implement test
    });

    test('returns approved status and sets API key cookie on success',
        () async {
      // TODO: Implement test
    });
  });
}
