import 'dart:convert';
import 'dart:io';

import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart';
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

    test('returns 200 healty when no subdomain matches', () async {
      final res = await http.get(
        TestEnv.apiUri('/health'),
      );
      expect(res.statusCode, equals(HttpStatus.ok));
      expect(res.body, equals('healthy'));
    });

    test('returns 403 for blacklisted path', () async {
      final res = await http.get(
        TestEnv.apiUri('/health'),
        headers: TestEnv.headersWithSubdomain(
          'api',
        ),
      );
      expect(res.statusCode, equals(HttpStatus.forbidden));
    });

    test('returns 307 for un-authed browser', () async {
      final uri = TestEnv.apiUri('/echo');
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers.addAll({
          'sec-fetch-mode': 'test',
          ...TestEnv.headersWithSubdomain('api'),
        });

      final res = await http.Client().send(request);

      expect(res.statusCode, equals(HttpStatus.temporaryRedirect));
      expect(res.headers[HttpHeaders.locationHeader], contains('/index.html'));
      expect(res.headers[HttpHeaders.locationHeader], isNot(contains('api')));
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
            HttpHeaders.authorizationHeader: 'Bearer dummy-key',
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
            ),
            HttpHeaders.authorizationHeader: 'Bearer dummy-key',
          },
        );
        expect(res.statusCode, equals(HttpStatus.forbidden));
      },
    );

    test(
      'returns 403 for invalid api key - value does not match stored',
      () async {
        final authToken = ChallengeVerificationResponse.random();
        await redis.set(
          ns: Namespace.authTokens,
          key: authToken.authToken,
          value: authToken.encode(),
        );
        final res = await http.get(
          TestEnv.apiUri('/echo'),
          headers: {
            ...TestEnv.headersWithSubdomain(
              'api',
            ),
            HttpHeaders.authorizationHeader:
                'Bearer ${authToken.authToken}-inalid',
          },
        );
        expect(res.statusCode, equals(HttpStatus.forbidden));
      },
    );

    test(
      'returns 403 for invalid api key - key expired',
      () async {
        final authToken = ChallengeVerificationResponse(
          authToken: 'expired-key',
          expiresAt: DateTime.now().subtract(
            const Duration(seconds: 30),
          ),
        );
        await redis.set(
          ns: Namespace.authTokens,
          key: authToken.authToken,
          value: authToken.encode(),
        );
        final res = await http.get(
          TestEnv.apiUri('/echo'),
          headers: {
            ...TestEnv.headersWithSubdomain(
              'api',
            ),
            HttpHeaders.authorizationHeader: 'Bearer ${authToken.authToken}',
          },
        );
        expect(res.statusCode, equals(HttpStatus.forbidden));
      },
    );

    test('returns 200 from upstream when api key is valid', () async {
      final authToken = ChallengeVerificationResponse.random();
      await redis.set(
        ns: Namespace.authTokens,
        key: authToken.authToken,
        value: authToken.encode(),
      );
      final res = await http.get(
        TestEnv.apiUri('/echo'),
        headers: {
          ...TestEnv.headersWithSubdomain(
            'api',
          ),
          HttpHeaders.authorizationHeader: 'Bearer ${authToken.authToken}',
        },
      );
      expect(res.statusCode, equals(HttpStatus.ok));
      final jsonBody = jsonDecode(res.body) as Map<String, dynamic>;
      expect(jsonBody['method'], equals('GET'));
      expect(jsonBody['path'], equals('/echo'));
    });

    test('returns 200 from upstream when api key is valid via cookie',
        () async {
      final authToken = ChallengeVerificationResponse.random();
      await redis.set(
        ns: Namespace.authTokens,
        key: authToken.authToken,
        value: authToken.encode(),
      );
      final res = await http.get(
        TestEnv.apiUri('/echo'),
        headers: {
          ...TestEnv.headersWithSubdomain(
            'api',
          ),
          HttpHeaders.cookieHeader: 'auth_token=${authToken.authToken}',
        },
      );
      expect(res.statusCode, equals(HttpStatus.ok));
      final jsonBody = jsonDecode(res.body) as Map<String, dynamic>;
      expect(jsonBody['method'], equals('GET'));
      expect(jsonBody['path'], equals('/echo'));
    });
  });
}
