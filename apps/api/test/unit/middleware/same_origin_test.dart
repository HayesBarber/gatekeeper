import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/middleware/same_origin.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockConfigService extends Mock implements ConfigService {}

void main() {
  group('sameOrigin middleware', () {
    late _MockRequestContext context;
    late _MockRequest request;
    late _MockConfigService configService;

    const fallthroughResponseBody = 'fallthrough response';

    Response handler(RequestContext context) {
      return Response(body: fallthroughResponseBody);
    }

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      configService = _MockConfigService();

      when(() => context.request).thenReturn(request);
      when(() => context.read<ConfigService>()).thenReturn(configService);
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

    group('when no origin header is present', () {
      test('should fall through to handler', () async {
        when(() => request.headers).thenReturn({});

        final response = await sameOrigin()(handler)(context);

        expect(response.statusCode, equals(HttpStatus.ok));
        final body = await response.body();
        expect(body, equals(fallthroughResponseBody));
      });
    });

    group('when origin header contains configured domain', () {
      test('should fall through to handler for exact domain match', () async {
        when(() => request.headers)
            .thenReturn({'origin': 'https://test-domain.com'});

        final response = await sameOrigin()(handler)(context);

        expect(response.statusCode, equals(HttpStatus.ok));
        final body = await response.body();
        expect(body, equals(fallthroughResponseBody));
      });

      test('should fall through to handler for subdomain match', () async {
        when(() => request.headers)
            .thenReturn({'origin': 'https://api.test-domain.com'});

        final response = await sameOrigin()(handler)(context);

        expect(response.statusCode, equals(HttpStatus.ok));
        final body = await response.body();
        expect(body, equals(fallthroughResponseBody));
      });

      test('should fall through to handler for domain with port', () async {
        when(() => request.headers)
            .thenReturn({'origin': 'https://test-domain.com:8080'});

        final response = await sameOrigin()(handler)(context);

        expect(response.statusCode, equals(HttpStatus.ok));
        final body = await response.body();
        expect(body, equals(fallthroughResponseBody));
      });

      test('should fall through to handler for HTTP protocol', () async {
        when(() => request.headers)
            .thenReturn({'origin': 'http://test-domain.com'});

        final response = await sameOrigin()(handler)(context);

        expect(response.statusCode, equals(HttpStatus.ok));
        final body = await response.body();
        expect(body, equals(fallthroughResponseBody));
      });
    });

    group('when origin header does not contain configured domain', () {
      test('should return forbidden status for completely different domain',
          () async {
        when(() => request.headers).thenReturn({'origin': 'https://evil.com'});

        final response = await sameOrigin()(handler)(context);

        expect(response.statusCode, equals(HttpStatus.forbidden));
      });

      test('should return forbidden status for similar but different domain',
          () async {
        when(() => request.headers)
            .thenReturn({'origin': 'https://test-domain.org'});

        final response = await sameOrigin()(handler)(context);

        expect(response.statusCode, equals(HttpStatus.forbidden));
      });

      test('should return forbidden status for partial match at beginning',
          () async {
        when(() => request.headers)
            .thenReturn({'origin': 'https://test-domain'});

        final response = await sameOrigin()(handler)(context);

        expect(response.statusCode, equals(HttpStatus.forbidden));
      });
    });

    group('edge cases', () {
      test('should handle empty origin header value', () async {
        when(() => request.headers).thenReturn({'origin': ''});

        final response = await sameOrigin()(handler)(context);

        expect(response.statusCode, equals(HttpStatus.forbidden));
      });

      test('should handle case-sensitive domain matching', () async {
        when(() => request.headers)
            .thenReturn({'origin': 'https://Test-Domain.com'});

        final response = await sameOrigin()(handler)(context);

        expect(response.statusCode, equals(HttpStatus.forbidden));
      });

      test('should handle origin header with special characters', () async {
        when(() => request.headers)
            .thenReturn({'origin': 'https://test-domain.com/path?query=value'});

        final response = await sameOrigin()(handler)(context);

        expect(response.statusCode, equals(HttpStatus.ok));
        final body = await response.body();
        expect(body, equals(fallthroughResponseBody));
      });
    });

    group('with different domain configurations', () {
      test('should work with complex domain names', () async {
        when(() => configService.config).thenReturn(
          AppConfig.fromJson({
            'redis': {
              'host': '127.0.0.1',
              'ttl': {'challenges': '30s', 'auth_tokens': '5m'},
            },
            'subdomains': <String, dynamic>{},
            'logging': {'enabled': true},
            'domain': 'api.v2.example.co.uk',
          }),
        );

        when(() => request.headers)
            .thenReturn({'origin': 'https://api.v2.example.co.uk'});

        final response = await sameOrigin()(handler)(context);

        expect(response.statusCode, equals(HttpStatus.ok));
        final body = await response.body();
        expect(body, equals(fallthroughResponseBody));
      });

      test('should handle domain with numbers', () async {
        when(() => configService.config).thenReturn(
          AppConfig.fromJson({
            'redis': {
              'host': '127.0.0.1',
              'ttl': {'challenges': '30s', 'auth_tokens': '5m'},
            },
            'subdomains': <String, dynamic>{},
            'logging': {'enabled': true},
            'domain': 'app123.example.com',
          }),
        );

        when(() => request.headers)
            .thenReturn({'origin': 'https://app123.example.com'});

        final response = await sameOrigin()(handler)(context);

        expect(response.statusCode, equals(HttpStatus.ok));
        final body = await response.body();
        expect(body, equals(fallthroughResponseBody));
      });
    });
  });
}
