import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/dto/challenge_verification_response.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
import 'package:gatekeeper/middleware/api_key_provider.dart';
import 'package:gatekeeper/middleware/client_id_provider.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/types/api_key_validation_result.dart';
import 'package:gatekeeper/util/api_key_validator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

class _MockWideEvent extends Mock implements we.WideEvent {}

class _MockRedisClient extends Mock implements RedisClientBase {}

void main() {
  group('ApiKeyValidator', () {
    late _MockRequestContext mockContext;
    late _MockWideEvent mockEventBuilder;
    late _MockRedisClient mockRedis;
    late ApiKeyContext apiKeyContext;
    late ClientIdContext clientIdContext;

    setUp(() {
      mockContext = _MockRequestContext();
      mockEventBuilder = _MockWideEvent();
      mockRedis = _MockRedisClient();
      apiKeyContext = const ApiKeyContext(
        apiKey: 'provided_api_key',
        source: 'header',
      );
      clientIdContext = const ClientIdContext(
        clientId: 'test_client_id',
        source: 'header',
      );
    });

    group('validateApiKeyContext', () {
      test('returns noApiKey when client ID is missing', () async {
        when(() => mockContext.read<ClientIdContext>())
            .thenReturn(const ClientIdContext(clientId: null, source: null));

        final result = await ApiKeyValidator.validateApiKeyContext(
          context: mockContext,
        );

        expect(result.isValid, isFalse);
        expect(result.error, equals(ApiKeyValidationError.noApiKey));
        verify(() => mockContext.read<ClientIdContext>()).called(1);
      });

      test('returns noApiKey when API key context has no key', () async {
        when(() => mockContext.read<ClientIdContext>())
            .thenReturn(clientIdContext);
        when(() => mockContext.read<ApiKeyContext>()).thenReturn(
          const ApiKeyContext(
            apiKey: null,
            source: null,
          ),
        );

        final result = await ApiKeyValidator.validateApiKeyContext(
          context: mockContext,
        );

        expect(result.isValid, isFalse);
        expect(result.error, equals(ApiKeyValidationError.noApiKey));
        verify(() => mockContext.read<ClientIdContext>()).called(1);
        verify(() => mockContext.read<ApiKeyContext>()).called(1);
      });

      test('returns failure when Redis lookup fails', () async {
        when(() => mockContext.read<ClientIdContext>())
            .thenReturn(clientIdContext);
        when(() => mockContext.read<ApiKeyContext>()).thenReturn(apiKeyContext);
        when(() => mockRedis.get(ns: Namespace.apiKeys, key: 'test_client_id'))
            .thenAnswer((_) async => null);

        // Act
        final result = await ApiKeyValidator.validateApiKeyContext(
          context: mockContext,
        );

        // Assert
        expect(result.isValid, isFalse);
        expect(result.error, equals(ApiKeyValidationError.apiKeyNotFound));
        verify(
          () => mockRedis.get(ns: Namespace.apiKeys, key: 'test_client_id'),
        ).called(1);
      });

      test('returns failure when API key does not match stored value',
          () async {
        final storedApiKey = ChallengeVerificationResponse(
          apiKey: 'stored_api_key',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(() => mockContext.read<ClientIdContext>())
            .thenReturn(clientIdContext);
        when(() => mockContext.read<ApiKeyContext>()).thenReturn(apiKeyContext);
        when(() => mockRedis.get(ns: Namespace.apiKeys, key: 'test_client_id'))
            .thenAnswer((_) async => storedApiKey.encode());

        final result = await ApiKeyValidator.validateApiKeyContext(
          context: mockContext,
        );

        expect(result.isValid, isFalse);
        expect(result.error, equals(ApiKeyValidationError.apiKeyInvalid));
        verify(() => mockContext.read<ClientIdContext>()).called(1);
        verify(() => mockContext.read<ApiKeyContext>()).called(1);
        verify(
          () => mockRedis.get(ns: Namespace.apiKeys, key: 'test_client_id'),
        ).called(1);
      });

      test('returns failure when API key has expired', () async {
        final expiredApiKey = ChallengeVerificationResponse(
          apiKey: 'stored_api_key',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        when(() => mockContext.read<ClientIdContext>())
            .thenReturn(clientIdContext);
        when(() => mockContext.read<ApiKeyContext>()).thenReturn(apiKeyContext);
        when(() => mockRedis.get(ns: Namespace.apiKeys, key: 'test_client_id'))
            .thenAnswer((_) async => expiredApiKey.encode());

        final result = await ApiKeyValidator.validateApiKeyContext(
          context: mockContext,
        );

        expect(result.isValid, isFalse);
        expect(result.error, equals(ApiKeyValidationError.apiKeyExpired));
        verify(() => mockContext.read<ClientIdContext>()).called(1);
        verify(() => mockContext.read<ApiKeyContext>()).called(1);
        verify(
          () => mockRedis.get(ns: Namespace.apiKeys, key: 'test_client_id'),
        ).called(1);
      });

      test('returns success when API key is valid', () async {
        final validApiKey = ChallengeVerificationResponse(
          apiKey: 'provided_api_key',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(() => mockContext.read<ClientIdContext>())
            .thenReturn(clientIdContext);
        when(() => mockContext.read<ApiKeyContext>()).thenReturn(apiKeyContext);
        when(() => mockRedis.get(ns: Namespace.apiKeys, key: 'test_client_id'))
            .thenAnswer((_) async => validApiKey.encode());

        final result = await ApiKeyValidator.validateApiKeyContext(
          context: mockContext,
        );

        expect(result.isValid, isTrue);
        expect(result.storedApiKey?.apiKey, equals('provided_api_key'));
        expect(result.error, isNull);
        verify(() => mockContext.read<ClientIdContext>()).called(1);
        verify(() => mockContext.read<ApiKeyContext>()).called(1);
        verify(
          () => mockRedis.get(ns: Namespace.apiKeys, key: 'test_client_id'),
        ).called(1);
      });

      test('updates event builder with validation results', () async {
        final validApiKey = ChallengeVerificationResponse(
          apiKey: 'provided_api_key',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(() => mockContext.read<ClientIdContext>())
            .thenReturn(clientIdContext);
        when(() => mockContext.read<ApiKeyContext>()).thenReturn(apiKeyContext);
        when(() => mockRedis.get(ns: Namespace.apiKeys, key: 'test_client_id'))
            .thenAnswer((_) async => validApiKey.encode());

        await ApiKeyValidator.validateApiKeyContext(
          context: mockContext,
        );

        verify(
          () => mockEventBuilder.authentication =
              any(named: 'authDurationMs', that: isA<int>()),
        ).called(1);
        verifyInOrder([
          () => mockContext.read<ClientIdContext>(),
          () => mockContext.read<ApiKeyContext>(),
          () => mockRedis.get(ns: Namespace.apiKeys, key: 'test_client_id'),
          () => mockEventBuilder.authentication =
              any(named: 'authDurationMs', that: isA<int>()),
        ]);
      });
    });

    group('validateApiKey', () {
      test('returns success when all parameters are valid', () async {
        final validApiKey = ChallengeVerificationResponse(
          apiKey: 'provided_api_key',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(() => mockRedis.get(ns: Namespace.apiKeys, key: 'test_client_id'))
            .thenAnswer((_) async => validApiKey.encode());

        final result = await ApiKeyValidator.validateApiKey(
          clientId: 'test_client_id',
          apiKey: 'provided_api_key',
          apiKeySource: 'header',
          redis: mockRedis,
          eventBuilder: mockEventBuilder,
        );

        expect(result.isValid, isTrue);
        expect(result.storedApiKey?.apiKey, equals('provided_api_key'));
        expect(result.error, isNull);
        verify(
          () => mockRedis.get(ns: Namespace.apiKeys, key: 'test_client_id'),
        ).called(1);
      });

      test('returns noApiKey when API key is empty', () async {
        final result = await ApiKeyValidator.validateApiKey(
          clientId: 'test_client_id',
          apiKey: '',
          apiKeySource: 'header',
          redis: mockRedis,
          eventBuilder: mockEventBuilder,
        );

        expect(result.isValid, isFalse);
        expect(result.error, equals(ApiKeyValidationError.noApiKey));
        expect(
          result.errorResponse?.statusCode,
          equals(HttpStatus.unauthorized),
        );
      });

      test('returns failure when Redis lookup returns null', () async {
        when(() => mockRedis.get(ns: Namespace.apiKeys, key: 'test_client_id'))
            .thenAnswer((_) async => null);

        final result = await ApiKeyValidator.validateApiKey(
          clientId: 'test_client_id',
          apiKey: 'provided_api_key',
          apiKeySource: 'header',
          redis: mockRedis,
          eventBuilder: mockEventBuilder,
        );

        expect(result.isValid, isFalse);
        expect(result.error, equals(ApiKeyValidationError.apiKeyNotFound));
        expect(result.errorResponse?.statusCode, equals(HttpStatus.forbidden));
        verify(
          () => mockRedis.get(ns: Namespace.apiKeys, key: 'test_client_id'),
        ).called(1);
      });
    });
  });
}
