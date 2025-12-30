import 'dart:io';

import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../util/test_env.dart';

void main() {
  group('Subdomain gatekeeper middleware', () {
    late RedisClientBase redis;

    setUpAll(() async {
      redis = await ShorebirdRedisClient.connect(
        host: TestEnv.redisHost,
      );
    });

    tearDown(() async {
      await redis.delete(
        ns: Namespace.challenges,
        key: TestEnv.clientId,
      );
      await redis.delete(
        ns: Namespace.apiKeys,
        key: TestEnv.clientId,
      );
    });

    tearDownAll(() async {
      await redis.close();
    });

    test('returns 200 healty when no subdomain matches', () async {
      final res = await http.get(
        TestEnv.apiUri('/health'),
      );
      expect(res.statusCode, equals(HttpStatus.ok));
      expect(res.body, equals('healthy'));
    });

    test('returns 200 healty when client ID header is missing', () async {
      final res = await http.get(
        TestEnv.apiUri('/health'),
        headers: TestEnv.headersWithSubdomain(
          'api',
          includeClientId: false,
        ),
      );
      expect(res.statusCode, equals(HttpStatus.ok));
      expect(res.body, equals('healthy'));
    });

    test('returns 403 for missing api key', () async {
      final res = await http.get(
        TestEnv.apiUri('/health'),
        headers: TestEnv.headersWithSubdomain(
          'api',
        ),
      );
      expect(res.statusCode, equals(HttpStatus.forbidden));
      expect(res.body, equals('Missing api key'));
    });

    test(
      'returns 403 for invalid api key - header present but no data',
      () async {
        final res = await http.get(
          TestEnv.apiUri('/health'),
          headers: {
            ...TestEnv.headersWithSubdomain(
              'api',
            ),
            headerApiKey: 'dummy-key',
          },
        );
        expect(res.statusCode, equals(HttpStatus.forbidden));
        expect(res.body, equals('Invalid api key'));
      },
    );

    test(
      'returns 403 for invalid api key - value does not match stored',
      () async {},
    );

    test('returns 200 from upstream when api key is valid', () async {});
  });
}
