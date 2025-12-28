import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/app_config.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:gatekeeper/dto/challenge_verification_request.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/challenge/verify.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockConfigService extends Mock implements ConfigService {}

class _MockRedisClient extends Mock implements RedisClientBase {}

void main() {
  group('POST /challenge/verify', () {
    late _MockRequestContext context;
    late _MockRequest request;
    late _MockConfigService configService;
    late _MockRedisClient redisClient;

    const clientIdHeader = 'X-Client-ID';
    const clientId = 'client-123';
    const publicKey = 'public-key';
    const challengeId = 'challenge-id';
    const challengeValue = 'challenge-value';

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
        AppConfig(
          clientIdHeader: clientIdHeader,
          redisHost: 'localhost',
        ),
      );
    });

    test('returns 401 if client ID header is missing', () async {
      when(() => request.headers).thenReturn({});

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
      expect(await response.body(), equals('Unauthorized'));
    });

    test('returns 401 if public key not found', () async {
      when(() => request.headers).thenReturn({clientIdHeader: clientId});
      when(
        () => redisClient.get(ns: Namespace.users, key: clientId),
      ).thenAnswer((_) async => null);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
      expect(await response.body(), equals('Unauthorized'));
    });

    test('returns 404 if challenge not found', () async {
      when(() => request.headers).thenReturn({clientIdHeader: clientId});
      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: challengeId,
          signature: 'sig',
        ).encode(),
      );

      when(
        () => redisClient.get(ns: Namespace.users, key: clientId),
      ).thenAnswer((_) async => publicKey);
      when(
        () => redisClient.get(ns: Namespace.challenges, key: clientId),
      ).thenAnswer((_) async => null);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.notFound));
      expect(await response.body(), equals('No challenge found'));
    });

    test('returns 400 if challenge ID does not match', () async {
      final challenge = ChallengeResponse(
        challengeId: challengeId,
        challenge: challengeValue,
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
      );

      when(() => request.headers).thenReturn({clientIdHeader: clientId});
      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: 'wrong-id',
          signature: 'sig',
        ).encode(),
      );

      when(
        () => redisClient.get(ns: Namespace.users, key: clientId),
      ).thenAnswer((_) async => publicKey);
      when(
        () => redisClient.get(ns: Namespace.challenges, key: clientId),
      ).thenAnswer((_) async => challenge.encode());

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(await response.body(), equals('Invalid challenge'));
    });

    test('returns 400 if challenge is expired', () async {
      final challenge = ChallengeResponse(
        challengeId: challengeId,
        challenge: challengeValue,
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );

      when(() => request.headers).thenReturn({clientIdHeader: clientId});
      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: challengeId,
          signature: 'sig',
        ).encode(),
      );

      when(
        () => redisClient.get(ns: Namespace.users, key: clientId),
      ).thenAnswer((_) async => publicKey);
      when(
        () => redisClient.get(ns: Namespace.challenges, key: clientId),
      ).thenAnswer((_) async => challenge.encode());

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(await response.body(), equals('Challenge expired'));
    });

    test('returns 403 if signature is invalid', () async {
      final challenge = ChallengeResponse(
        challengeId: challengeId,
        challenge: challengeValue,
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
      );

      when(() => request.headers).thenReturn({clientIdHeader: clientId});
      when(() => request.body()).thenAnswer(
        (_) async => ChallengeVerificationRequest(
          challengeId: challengeId,
          signature: 'bad-sig',
        ).encode(),
      );

      when(
        () => redisClient.get(ns: Namespace.users, key: clientId),
      ).thenAnswer((_) async => publicKey);
      when(
        () => redisClient.get(ns: Namespace.challenges, key: clientId),
      ).thenAnswer((_) async => challenge.encode());

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.forbidden));
      expect(await response.body(), equals('Invalid signature'));
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
