import 'dart:convert';
import 'dart:io';

import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart';
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
        ns: Namespace.authTokens,
        key: TestEnv.deviceId,
      );
    });

    tearDownAll(() async {
      await redis.close();
    });

    test('blocks access to blacklisted paths', () async {
      final authToken = ChallengeVerificationResponse.random();
      await redis.set(
        ns: Namespace.authTokens,
        key: authToken.authToken,
        value: authToken.encode(),
      );

      final blacklistedGetRes = await http.get(
        TestEnv.apiUri('/admin/users'),
        headers: {
          ...TestEnv.headersWithSubdomain('api'),
          HttpHeaders.authorizationHeader: 'Bearer ${authToken.authToken}',
        },
      );
      expect(blacklistedGetRes.statusCode, equals(HttpStatus.forbidden));

      final blacklistedPostRes = await http.post(
        TestEnv.apiUri('/users/delete'),
        headers: {
          ...TestEnv.headersWithSubdomain('api'),
          HttpHeaders.authorizationHeader: 'Bearer ${authToken.authToken}',
        },
      );
      expect(blacklistedPostRes.statusCode, equals(HttpStatus.forbidden));
    });

    test('allows access to non-blacklisted paths', () async {
      final authToken = ChallengeVerificationResponse.random();
      await redis.set(
        ns: Namespace.authTokens,
        key: authToken.authToken,
        value: authToken.encode(),
      );

      final allowedGetRes = await http.get(
        TestEnv.apiUri('/api/data'),
        headers: {
          ...TestEnv.headersWithSubdomain('api'),
          HttpHeaders.authorizationHeader: 'Bearer ${authToken.authToken}',
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
          HttpHeaders.authorizationHeader: 'Bearer ${authToken.authToken}',
        },
      );
      expect(allowedPostRes.statusCode, equals(HttpStatus.ok));
      final jsonBody2 = jsonDecode(allowedPostRes.body) as Map<String, dynamic>;
      expect(jsonBody2['method'], equals('POST'));
      expect(jsonBody2['path'], equals('/users/create'));
    });

    test('respects method-specific blacklists', () async {
      final authToken = ChallengeVerificationResponse.random();
      await redis.set(
        ns: Namespace.authTokens,
        key: authToken.authToken,
        value: authToken.encode(),
      );

      final getRes = await http.get(
        TestEnv.apiUri('/admin/users'),
        headers: {
          ...TestEnv.headersWithSubdomain('api'),
          HttpHeaders.authorizationHeader: 'Bearer ${authToken.authToken}',
        },
      );
      expect(getRes.statusCode, equals(HttpStatus.forbidden));

      final putRes = await http.put(
        TestEnv.apiUri('/admin/users'),
        headers: {
          ...TestEnv.headersWithSubdomain('api'),
          HttpHeaders.authorizationHeader: 'Bearer ${authToken.authToken}',
        },
      );
      expect(putRes.statusCode, equals(HttpStatus.ok));
    });
  });
}
