import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';
import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';
import 'package:gatekeeper_dto/gatekeeper_dto.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/challenge/verify.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockConfigService extends Mock implements ConfigService {}

class _MockRedisClient extends Mock implements RedisClientBase {}

class _MockSignatureVerifier extends Mock {
  bool call(String m, String s, String k);
}

void main() {
  group('POST /challenge/verify', () {
    late _MockRequestContext context;
    late _MockRequest request;
    late _MockConfigService configService;
    late _MockRedisClient redisClient;
    late _MockSignatureVerifier verifier;

    const deviceId = 'device-123';
    const publicKey = 'public-key';
    const challengeId = 'challenge-id';
    const challengeValue = 'challenge-value';

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      configService = _MockConfigService();
      redisClient = _MockRedisClient();
      verifier = _MockSignatureVerifier();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<ConfigService>()).thenReturn(configService);
      when(() => context.read<RedisClientBase>()).thenReturn(redisClient);
      when(() => context.read<SignatureVerifier>()).thenReturn(verifier.call);

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

    test('returns 401 if public key not found', () async {
      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: challengeId,
          signature: 'sig',
          deviceId: deviceId,
        ).encode(),
      );
      when(
        () => redisClient.get(ns: Namespace.devices, key: deviceId),
      ).thenAnswer((_) async => null);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns 404 if challenge not found', () async {
      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: challengeId,
          signature: 'sig',
          deviceId: deviceId,
        ).encode(),
      );

      when(
        () => redisClient.get(ns: Namespace.devices, key: deviceId),
      ).thenAnswer((_) async => publicKey);
      when(
        () => redisClient.get(ns: Namespace.challenges, key: challengeId),
      ).thenAnswer((_) async => null);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.notFound));
    });

    test('returns 400 if challenge ID does not match', () async {
      final challenge = ChallengeResponse(
        challengeId: challengeId,
        challenge: challengeValue,
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
        sessionId: 'test-session-id',
      );
      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: 'wrong-id',
          signature: 'sig',
          deviceId: deviceId,
        ).encode(),
      );

      when(
        () => redisClient.get(ns: Namespace.devices, key: deviceId),
      ).thenAnswer((_) async => publicKey);
      when(
        () => redisClient.get(ns: Namespace.challenges, key: 'wrong-id'),
      ).thenAnswer((_) async => challenge.encode());

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('returns 400 if challenge is expired', () async {
      final challenge = ChallengeResponse(
        challengeId: challengeId,
        challenge: challengeValue,
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
        sessionId: 'test-session-id',
      );

      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: challengeId,
          signature: 'sig',
          deviceId: deviceId,
        ).encode(),
      );

      when(
        () => redisClient.get(ns: Namespace.devices, key: deviceId),
      ).thenAnswer((_) async => publicKey);
      when(
        () => redisClient.get(ns: Namespace.challenges, key: challengeId),
      ).thenAnswer((_) async => challenge.encode());

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('returns 403 if signature is invalid', () async {
      final challenge = ChallengeResponse(
        challengeId: challengeId,
        challenge: challengeValue,
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
        sessionId: 'test-session-id',
      );

      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: challengeId,
          signature: 'bad-sig',
          deviceId: deviceId,
        ).encode(),
      );

      when(
        () => redisClient.get(ns: Namespace.devices, key: deviceId),
      ).thenAnswer((_) async => publicKey);
      when(
        () => redisClient.get(ns: Namespace.challenges, key: challengeId),
      ).thenAnswer((_) async => challenge.encode());
      when(
        () => verifier(
          challengeValue,
          'bad-sig',
          publicKey,
        ),
      ).thenReturn(false);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test('returns 200 and api key for valid challenge verification', () async {
      final challenge = ChallengeResponse(
        challengeId: challengeId,
        challenge: challengeValue,
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
        sessionId: 'test-session-id',
      );

      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: challengeId,
          signature: 'valid-signature',
          deviceId: deviceId,
        ).encode(),
      );

      when(
        () => redisClient.get(ns: Namespace.devices, key: deviceId),
      ).thenAnswer((_) async => publicKey);

      when(
        () => redisClient.get(ns: Namespace.challenges, key: challengeId),
      ).thenAnswer((_) async => challenge.encode());

      when(
        () => verifier(
          challengeValue,
          'valid-signature',
          publicKey,
        ),
      ).thenReturn(true);

      when(
        () => redisClient.set(
          ns: Namespace.authTokens,
          key: any(named: 'key'),
          value: any(named: 'value'),
          ttl: any(named: 'ttl'),
        ),
      ).thenAnswer((_) async => {});
      when(
        () => redisClient.set(
          ns: Namespace.challenges,
          key: any(named: 'key'),
          value: any(named: 'value'),
          ttl: any(named: 'ttl'),
        ),
      ).thenAnswer((_) async => {});

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));

      final body = await response.body();
      final authTokenResponse = ChallengeVerificationResponse.decode(body);
      expect(authTokenResponse.authToken, isNotEmpty);
      expect(authTokenResponse.expiresAt, isNotNull);
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
      HttpMethod.get,
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
