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

    test('returns 403 for missing client id', () async {
      final res = await http.get(
        TestEnv.apiUri('/health'),
        headers: TestEnv.headersWithSubdomain(
          'api',
          includeClientId: false,
        ),
      );
      expect(res.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns 403 for missing api key', () async {
      final res = await http.get(
        TestEnv.apiUri('/echo'),
        headers: TestEnv.headersWithSubdomain(
          'api',
        ),
      );
      expect(res.statusCode, equals(HttpStatus.unauthorized));
    });

    test(
      'returns 403 for invalid api key - header present but no data',
      () async {
        final res = await http.get(
          TestEnv.apiUri('/echo'),
          headers: {
            ...TestEnv.headersWithSubdomain(
              'api',
            ),
            headerApiKey: 'dummy-key',
          },
        );
        expect(res.statusCode, equals(HttpStatus.forbidden));
      },
    );

    test(
      // ignore: lines_longer_than_80_chars
      'returns 403 for invalid api key - header present but no data: invalid client id',
      () async {
        final res = await http.get(
          TestEnv.apiUri('/echo'),
          headers: {
            ...TestEnv.headersWithSubdomain(
              'api',
              includeClientId: false,
            ),
            headerRequestorId: '${TestEnv.clientId}-invalid',
            headerApiKey: 'dummy-key',
          },
        );
        expect(res.statusCode, equals(HttpStatus.forbidden));
      },
    );

    test(
      'returns 403 for invalid api key - value does not match stored',
      () async {
        final apiKey = ChallengeVerificationResponse.random();
        await redis.set(
          ns: Namespace.apiKeys,
          key: TestEnv.clientId,
          value: apiKey.encode(),
        );
        final res = await http.get(
          TestEnv.apiUri('/echo'),
          headers: {
            ...TestEnv.headersWithSubdomain(
              'api',
            ),
            headerApiKey: '${apiKey.apiKey}-inalid',
          },
        );
        expect(res.statusCode, equals(HttpStatus.forbidden));
      },
    );

    test(
      'returns 403 for invalid api key - key expired',
      () async {
        final apiKey = ChallengeVerificationResponse(
          apiKey: 'expired-key',
          expiresAt: DateTime.now().subtract(
            const Duration(seconds: 30),
          ),
        );
        await redis.set(
          ns: Namespace.apiKeys,
          key: TestEnv.clientId,
          value: apiKey.encode(),
        );
        final res = await http.get(
          TestEnv.apiUri('/echo'),
          headers: {
            ...TestEnv.headersWithSubdomain(
              'api',
            ),
            headerApiKey: apiKey.apiKey,
          },
        );
        expect(res.statusCode, equals(HttpStatus.forbidden));
      },
    );

    test('returns 200 from upstream when api key is valid', () async {
      final apiKey = ChallengeVerificationResponse.random();
      await redis.set(
        ns: Namespace.apiKeys,
        key: TestEnv.clientId,
        value: apiKey.encode(),
      );
      final res = await http.get(
        TestEnv.apiUri('/echo'),
        headers: {
          ...TestEnv.headersWithSubdomain(
            'api',
          ),
          headerApiKey: apiKey.apiKey,
        },
      );
      expect(res.statusCode, equals(HttpStatus.ok));
      final jsonBody = jsonDecode(res.body) as Map<String, dynamic>;
      expect(jsonBody['method'], equals('GET'));
      expect(jsonBody['path'], equals('/echo'));
    });
  });
}
