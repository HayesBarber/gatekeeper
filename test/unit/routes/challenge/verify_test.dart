import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/app_config.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/config/logging_config.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:gatekeeper/dto/challenge_verification_request.dart';
import 'package:gatekeeper/dto/challenge_verification_response.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/types/signature_verifier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/challenge/verify.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockConfigService extends Mock implements ConfigService {}

class _MockRedisClient extends Mock implements RedisClientBase {}

class _MockWideEvent extends Mock implements we.WideEvent {}

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
    late _MockWideEvent wideEvent;

    const clientId = 'client-123';
    const publicKey = 'public-key';
    const challengeId = 'challenge-id';
    const challengeValue = 'challenge-value';

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      configService = _MockConfigService();
      redisClient = _MockRedisClient();
      verifier = _MockSignatureVerifier();
      wideEvent = _MockWideEvent();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<ConfigService>()).thenReturn(configService);
      when(() => context.read<RedisClientBase>()).thenReturn(redisClient);
      when(() => context.read<SignatureVerifier>()).thenReturn(verifier.call);
      when(() => context.read<we.WideEvent>()).thenReturn(wideEvent);

      when(() => configService.config).thenReturn(
        AppConfig(
          redisHost: 'localhost',
          subdomains: {},
          logging: const LoggingConfig.defaultConfig(),
        ),
      );
    });

    test('returns 401 if public key not found', () async {
      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: challengeId,
          signature: 'sig',
          deviceId: clientId,
        ).encode(),
      );
      when(
        () => redisClient.get(ns: Namespace.devices, key: clientId),
      ).thenAnswer((_) async => null);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns 404 if challenge not found', () async {
      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: challengeId,
          signature: 'sig',
          deviceId: clientId,
        ).encode(),
      );

      when(
        () => redisClient.get(ns: Namespace.devices, key: clientId),
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
      );
      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: 'wrong-id',
          signature: 'sig',
          deviceId: clientId,
        ).encode(),
      );

      when(
        () => redisClient.get(ns: Namespace.devices, key: clientId),
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
      );

      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: challengeId,
          signature: 'sig',
          deviceId: clientId,
        ).encode(),
      );

      when(
        () => redisClient.get(ns: Namespace.devices, key: clientId),
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
      );

      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: challengeId,
          signature: 'bad-sig',
          deviceId: clientId,
        ).encode(),
      );

      when(
        () => redisClient.get(ns: Namespace.devices, key: clientId),
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
      );

      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: challengeId,
          signature: 'valid-signature',
          deviceId: clientId,
        ).encode(),
      );

      when(
        () => redisClient.get(ns: Namespace.devices, key: clientId),
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
          ns: Namespace.apiKeys,
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async => {});

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));

      final body = await response.body();
      final apiKeyResponse = ChallengeVerificationResponse.decode(body);
      expect(apiKeyResponse.apiKey, isNotEmpty);
      expect(apiKeyResponse.expiresAt, isNotNull);
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
