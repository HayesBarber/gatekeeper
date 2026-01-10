import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/middleware/auth_token_provider.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/types/auth_token_validation_result.dart';
import 'package:gatekeeper/util/auth_token_validator.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart' as gc;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

class _MockWideEvent extends Mock implements gc.WideEvent {}

class _MockRedisClient extends Mock implements RedisClientBase {}

void main() {
  group('AuthTokenValidator', () {
    late _MockRequestContext mockContext;
    late _MockWideEvent mockEventBuilder;
    late _MockRedisClient mockRedis;
    late AuthTokenContext authTokenContext;

    setUp(() {
      mockContext = _MockRequestContext();
      mockEventBuilder = _MockWideEvent();
      mockRedis = _MockRedisClient();
      authTokenContext = const AuthTokenContext(
        authToken: 'provided_auth_token',
        source: 'header',
      );
      when(() => mockContext.read<gc.WideEvent>()).thenReturn(mockEventBuilder);
      when(() => mockContext.read<RedisClientBase>()).thenReturn(mockRedis);
    });

    group('validateAuthTokenContext', () {
      test('returns noAuthToken when API key context has no key', () async {
        when(() => mockContext.read<AuthTokenContext>()).thenReturn(
          const AuthTokenContext(
            authToken: null,
            source: null,
          ),
        );

        final result = await AuthTokenValidator.validateAuthTokenContext(
          context: mockContext,
        );

        expect(result.isValid, isFalse);
        expect(result.error, equals(AuthTokenValidationError.noAuthToken));
        verify(() => mockContext.read<AuthTokenContext>()).called(1);
      });

      test('returns failure when Redis lookup fails', () async {
        when(() => mockContext.read<AuthTokenContext>()).thenReturn(
          authTokenContext,
        );
        when(
          () => mockRedis.get(
            ns: Namespace.authTokens,
            key: 'provided_auth_token',
          ),
        ).thenAnswer((_) async => null);

        final result = await AuthTokenValidator.validateAuthTokenContext(
          context: mockContext,
        );

        expect(result.isValid, isFalse);
        expect(
          result.error,
          equals(
            AuthTokenValidationError.authTokenNotFound,
          ),
        );
        verify(
          () => mockRedis.get(
            ns: Namespace.authTokens,
            key: 'provided_auth_token',
          ),
        ).called(1);
      });

      test('returns failure when API key does not match stored value',
          () async {
        final storedAuthToken = gc.ChallengeVerificationResponse(
          authToken: 'stored_auth_token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(() => mockContext.read<AuthTokenContext>())
            .thenReturn(authTokenContext);
        when(
          () => mockRedis.get(
            ns: Namespace.authTokens,
            key: 'provided_auth_token',
          ),
        ).thenAnswer((_) async => storedAuthToken.encode());

        final result = await AuthTokenValidator.validateAuthTokenContext(
          context: mockContext,
        );

        expect(result.isValid, isFalse);
        expect(result.error, equals(AuthTokenValidationError.authTokenInvalid));
        verify(() => mockContext.read<AuthTokenContext>()).called(1);
        verify(
          () => mockRedis.get(
            ns: Namespace.authTokens,
            key: 'provided_auth_token',
          ),
        ).called(1);
      });

      test('returns failure when API key has expired', () async {
        final expiredAuthToken = gc.ChallengeVerificationResponse(
          authToken: 'provided_auth_token',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        when(() => mockContext.read<AuthTokenContext>())
            .thenReturn(authTokenContext);
        when(
          () => mockRedis.get(
            ns: Namespace.authTokens,
            key: 'provided_auth_token',
          ),
        ).thenAnswer((_) async => expiredAuthToken.encode());

        final result = await AuthTokenValidator.validateAuthTokenContext(
          context: mockContext,
        );

        expect(result.isValid, isFalse);
        expect(result.error, equals(AuthTokenValidationError.authTokenExpired));
        verify(() => mockContext.read<AuthTokenContext>()).called(1);
        verify(
          () => mockRedis.get(
            ns: Namespace.authTokens,
            key: 'provided_auth_token',
          ),
        ).called(1);
      });

      test('returns success when API key is valid', () async {
        final validAuthToken = gc.ChallengeVerificationResponse(
          authToken: 'provided_auth_token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(() => mockContext.read<AuthTokenContext>())
            .thenReturn(authTokenContext);
        when(
          () => mockRedis.get(
            ns: Namespace.authTokens,
            key: 'provided_auth_token',
          ),
        ).thenAnswer((_) async => validAuthToken.encode());

        final result = await AuthTokenValidator.validateAuthTokenContext(
          context: mockContext,
        );

        expect(result.isValid, isTrue);
        expect(
          result.storedAuthToken?.authToken,
          equals('provided_auth_token'),
        );
        expect(result.error, isNull);
        verify(() => mockContext.read<AuthTokenContext>()).called(1);
        verify(
          () => mockRedis.get(
            ns: Namespace.authTokens,
            key: 'provided_auth_token',
          ),
        ).called(1);
      });

      test('updates event builder with validation results', () async {
        final validAuthToken = gc.ChallengeVerificationResponse(
          authToken: 'provided_auth_token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(() => mockContext.read<AuthTokenContext>())
            .thenReturn(authTokenContext);
        when(
          () => mockRedis.get(
            ns: Namespace.authTokens,
            key: 'provided_auth_token',
          ),
        ).thenAnswer((_) async => validAuthToken.encode());

        final result = await AuthTokenValidator.validateAuthTokenContext(
          context: mockContext,
        );

        expect(result.isValid, isTrue);
        verify(
          () => mockEventBuilder.authentication = any(
            that: isA<gc.AuthenticationContext>(),
          ),
        ).called(1);
      });
    });

    group('validateAuthToken', () {
      test('returns success when all parameters are valid', () async {
        final validAuthToken = gc.ChallengeVerificationResponse(
          authToken: 'provided_auth_token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(
          () => mockRedis.get(
            ns: Namespace.authTokens,
            key: 'provided_auth_token',
          ),
        ).thenAnswer((_) async => validAuthToken.encode());

        final result = await AuthTokenValidator.validateAuthToken(
          authToken: 'provided_auth_token',
          authTokenSource: 'header',
          redis: mockRedis,
          eventBuilder: mockEventBuilder,
        );

        expect(result.isValid, isTrue);
        expect(
          result.storedAuthToken?.authToken,
          equals('provided_auth_token'),
        );
        expect(result.error, isNull);
        verify(
          () => mockRedis.get(
            ns: Namespace.authTokens,
            key: 'provided_auth_token',
          ),
        ).called(1);
      });

      test('returns noAuthToken when API key is empty', () async {
        final result = await AuthTokenValidator.validateAuthToken(
          authToken: '',
          authTokenSource: 'header',
          redis: mockRedis,
          eventBuilder: mockEventBuilder,
        );

        expect(result.isValid, isFalse);
        expect(result.error, equals(AuthTokenValidationError.noAuthToken));
        expect(
          result.errorResponse?.statusCode,
          equals(HttpStatus.unauthorized),
        );
      });

      test('returns failure when Redis lookup returns null', () async {
        when(
          () => mockRedis.get(
            ns: Namespace.authTokens,
            key: 'provided_auth_token',
          ),
        ).thenAnswer((_) async => null);

        final result = await AuthTokenValidator.validateAuthToken(
          authToken: 'provided_auth_token',
          authTokenSource: 'header',
          redis: mockRedis,
          eventBuilder: mockEventBuilder,
        );

        expect(result.isValid, isFalse);
        expect(
          result.error,
          equals(AuthTokenValidationError.authTokenNotFound),
        );
        expect(result.errorResponse?.statusCode, equals(HttpStatus.forbidden));
        verify(
          () => mockRedis.get(
            ns: Namespace.authTokens,
            key: 'provided_auth_token',
          ),
        ).called(1);
      });
    });
  });
}
