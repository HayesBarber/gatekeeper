import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart' as gc;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/challenge/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockConfigService extends Mock implements ConfigService {}

class _MockRedisClient extends Mock implements RedisClientBase {}

void main() {
  group('POST /challenge', () {
    late _MockRequestContext context;
    late _MockRequest request;
    late _MockConfigService configService;
    late _MockRedisClient redisClient;

    const redisUserKey = 'user-123';

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      configService = _MockConfigService();
      redisClient = _MockRedisClient();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<ConfigService>()).thenReturn(configService);
      when(() => context.read<RedisClientBase>()).thenReturn(redisClient);

      when(() => configService.config).thenReturn(
        AppConfig.fromJson({
          'redis': {
            'host': '127.0.0.1',
            'ttl': {'challenges': '30s', 'auth_tokens': '5m'},
          },
          'subdomains': <String, dynamic>{},
          'logging': {'enabled': true},
          'domain': 'test-domain.com',
        }),
      );
    });

    test('returns 200 and challenge', () async {
      when(
        () => redisClient.get(
          ns: Namespace.devices,
          key: any(named: 'key'),
        ),
      ).thenAnswer((_) async => redisUserKey);
      when(
        () => redisClient.set(
          ns: Namespace.challenges,
          key: any(named: 'key'),
          value: any(named: 'value'),
          ttl: any(named: 'ttl'),
        ),
      ).thenAnswer(
        (_) async => {},
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));

      final body = await response.body();
      final jsonBody = jsonDecode(body) as Map<String, dynamic>;
      final challenge = gc.ChallengeResponse(
        challengeId: jsonBody['challenge_id'] as String,
        challenge: jsonBody['challenge'] as String,
        expiresAt: DateTime.parse(jsonBody['expires_at'] as String),
        sessionId: '',
        challengeCode: jsonBody['challenge_code'] as String,
      );
      expect(challenge.challengeId, isNotEmpty);
      expect(challenge.challenge, isNotEmpty);
      expect(challenge.expiresAt, isNotNull);
    });
  });

  group('non-POST methods', () {
    late Request request;
    late RequestContext context;

    setUp(() {
      request = _MockRequest();
      context = _MockRequestContext();

      when(() => context.request).thenReturn(request);
    });

    final methods = <HttpMethod>[
      HttpMethod.put,
      HttpMethod.patch,
      HttpMethod.delete,
      HttpMethod.head,
      HttpMethod.options,
    ];

    for (final method in methods) {
      test('${method.name.toUpperCase()} returns 405', () async {
        when(() => request.method).thenReturn(method);
        when(() => request.headers).thenReturn({});

        final response = await route.onRequest(context);

        expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      });
    }
  });
}
