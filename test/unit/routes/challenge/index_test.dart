import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/app_config.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/config/logging_config.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
import 'package:gatekeeper/middleware/client_id_provider.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/challenge/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockConfigService extends Mock implements ConfigService {}

class _MockRedisClient extends Mock implements RedisClientBase {}

class _MockWideEvent extends Mock implements we.WideEvent {}

class _MockClientIdContext extends Mock implements ClientIdContext {}

void main() {
  group('POST /challenge', () {
    late _MockRequestContext context;
    late _MockRequest request;
    late _MockConfigService configService;
    late _MockRedisClient redisClient;
    late _MockWideEvent wideEvent;
    late _MockClientIdContext clientIdContext;

    const clientId = 'client-123';
    const redisUserKey = 'user-123';
    const redisHost = '127.0.0.1';

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      configService = _MockConfigService();
      redisClient = _MockRedisClient();
      wideEvent = _MockWideEvent();
      clientIdContext = _MockClientIdContext();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<ConfigService>()).thenReturn(configService);
      when(() => context.read<RedisClientBase>()).thenReturn(redisClient);
      when(() => context.read<we.WideEvent>()).thenReturn(wideEvent);
      when(() => context.read<ClientIdContext>()).thenReturn(clientIdContext);

      when(() => configService.config).thenReturn(
        AppConfig(
          redisHost: redisHost,
          subdomains: {},
          logging: const LoggingConfig.defaultConfig(),
        ),
      );
    });

    test('returns 401 if client ID header is missing', () async {
      when(() => request.headers).thenReturn({});

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns 401 if user not found in Redis', () async {
      when(() => request.headers).thenReturn({headerRequestorId: clientId});
      when(
        () => redisClient.get(
          ns: Namespace.users,
          key: any(named: 'key'),
        ),
      ).thenAnswer((_) async => null);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns 200 and challenge if user exists', () async {
      when(() => request.headers).thenReturn({headerRequestorId: clientId});
      when(() => clientIdContext.clientId).thenReturn(clientId);
      when(
        () => redisClient.get(
          ns: Namespace.users,
          key: any(named: 'key'),
        ),
      ).thenAnswer((_) async => redisUserKey);
      when(
        () => redisClient.get(
          ns: Namespace.challenges,
          key: any(named: 'key'),
        ),
      ).thenAnswer((_) async => null);
      when(
        () => redisClient.set(
          ns: Namespace.challenges,
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer(
        (_) async => {},
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));

      final body = await response.body();
      final challenge = ChallengeResponse.decode(body);
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
