import 'dart:convert';
import 'dart:io';

import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/dto/challenge_verification_response.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../util/test_env.dart';

void main() {
  group('Subdomain blacklist functionality', () {
    late RedisClientBase redis;

    setUpAll(() async {
      redis = await ShorebirdRedisClient.connect(
        host: TestEnv.redisHost,
      );
    });

    tearDown(() async {
      await redis.delete(
        ns: Namespace.challenges,
        key: TestEnv.deviceId,
      );
      await redis.delete(
        ns: Namespace.apiKeys,
        key: TestEnv.deviceId,
      );
    });

    tearDownAll(() async {
      await redis.close();
    });

    test('blocks access to blacklisted paths', () async {
      final apiKey = ChallengeVerificationResponse.random();
      await redis.set(
        ns: Namespace.apiKeys,
        key: apiKey.apiKey,
        value: apiKey.encode(),
      );

      final blacklistedGetRes = await http.get(
        TestEnv.apiUri('/admin/users'),
        headers: {
          ...TestEnv.headersWithSubdomain('api'),
          headerAuthorization: 'Bearer ${apiKey.apiKey}',
        },
      );
      expect(blacklistedGetRes.statusCode, equals(HttpStatus.forbidden));

      final blacklistedPostRes = await http.post(
        TestEnv.apiUri('/users/delete'),
        headers: {
          ...TestEnv.headersWithSubdomain('api'),
          headerAuthorization: 'Bearer ${apiKey.apiKey}',
        },
      );
      expect(blacklistedPostRes.statusCode, equals(HttpStatus.forbidden));
    });

    test('allows access to non-blacklisted paths', () async {
      final apiKey = ChallengeVerificationResponse.random();
      await redis.set(
        ns: Namespace.apiKeys,
        key: apiKey.apiKey,
        value: apiKey.encode(),
      );

      final allowedGetRes = await http.get(
        TestEnv.apiUri('/api/data'),
        headers: {
          ...TestEnv.headersWithSubdomain('api'),
          headerAuthorization: 'Bearer ${apiKey.apiKey}',
        },
      );
      expect(allowedGetRes.statusCode, equals(HttpStatus.ok));
      final jsonBody = jsonDecode(allowedGetRes.body) as Map<String, dynamic>;
      expect(jsonBody['method'], equals('GET'));
      expect(jsonBody['path'], equals('/api/data'));

      final allowedPostRes = await http.post(
        TestEnv.apiUri('/users/create'),
        headers: {
          ...TestEnv.headersWithSubdomain('api'),
          headerAuthorization: 'Bearer ${apiKey.apiKey}',
        },
      );
      expect(allowedPostRes.statusCode, equals(HttpStatus.ok));
      final jsonBody2 = jsonDecode(allowedPostRes.body) as Map<String, dynamic>;
      expect(jsonBody2['method'], equals('POST'));
      expect(jsonBody2['path'], equals('/users/create'));
    });

    test('respects method-specific blacklists', () async {
      final apiKey = ChallengeVerificationResponse.random();
      await redis.set(
        ns: Namespace.apiKeys,
        key: apiKey.apiKey,
        value: apiKey.encode(),
      );

      final getRes = await http.get(
        TestEnv.apiUri('/admin/users'),
        headers: {
          ...TestEnv.headersWithSubdomain('api'),
          headerAuthorization: 'Bearer ${apiKey.apiKey}',
        },
      );
      expect(getRes.statusCode, equals(HttpStatus.forbidden));

      final putRes = await http.put(
        TestEnv.apiUri('/admin/users'),
        headers: {
          ...TestEnv.headersWithSubdomain('api'),
          headerAuthorization: 'Bearer ${apiKey.apiKey}',
        },
      );
      expect(putRes.statusCode, equals(HttpStatus.ok));
    });
  });
}
