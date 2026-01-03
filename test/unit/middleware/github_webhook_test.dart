import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/app_config.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/config/logging_config.dart';
import 'package:gatekeeper/config/subdomain_config.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/middleware/github_webhook.dart';
import 'package:gatekeeper/util/forward_to_upstream.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockConfigService extends Mock implements ConfigService {}

class _MockForward extends Mock implements Forward {}

void main() {
  group('GitHub webhook middleware', () {
    late _MockRequestContext context;
    late _MockRequest request;
    late _MockConfigService configService;
    late _MockForward forward;

    const fallthroughResponseBody = 'hello world';
    const upstreamResponseBody = 'upstream response';

    Response handler(context) {
      return Response(body: fallthroughResponseBody);
    }

    setUpAll(() {
      registerFallbackValue(Uri.parse('http://example.com/'));
    });

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      configService = _MockConfigService();
      forward = _MockForward();

      when(() => context.request).thenReturn(request);
      when(() => context.read<ConfigService>()).thenReturn(configService);
      when(() => context.read<Forward>()).thenReturn(forward);
    });

    test('Falls through when no match', () async {
      when(() => request.uri).thenReturn(Uri.parse('http://example.com/'));
      final res = await githubWebhook()(handler)(context);
      expect(res.statusCode, equals(HttpStatus.ok));
      final body = await res.body();
      expect(body, fallthroughResponseBody);
    });

    test('Falls through when no subdomain config', () async {
      when(() => request.uri).thenReturn(
        Uri.parse('http://github.example.com/'),
      );
      when(() => configService.config).thenReturn(
        AppConfig(
          redisHost: '',
          subdomains: {},
          logging: const LoggingConfig.defaultConfig(),
        ),
      );
      final res = await githubWebhook()(handler)(context);
      expect(res.statusCode, equals(HttpStatus.ok));
      final body = await res.body();
      expect(body, fallthroughResponseBody);
    });

    test('Falls through when no secret', () async {
      when(() => request.uri).thenReturn(
        Uri.parse('http://github.example.com/'),
      );
      when(() => configService.config).thenReturn(
        AppConfig(
          redisHost: '',
          subdomains: {
            'github': const SubdomainConfig(
              url: 'testing',
            ),
          },
          logging: const LoggingConfig.defaultConfig(),
        ),
      );
      final res = await githubWebhook()(handler)(context);
      expect(res.statusCode, equals(HttpStatus.ok));
      final body = await res.body();
      expect(body, fallthroughResponseBody);
    });

    test('Unauthorized when no signature header', () async {
      when(() => request.uri).thenReturn(
        Uri.parse('http://github.example.com/'),
      );
      when(() => configService.config).thenReturn(
        AppConfig(
          redisHost: '',
          subdomains: {
            'github': const SubdomainConfig(
              url: 'testing',
              secret: 'invalid',
            ),
          },
          logging: const LoggingConfig.defaultConfig(),
        ),
      );
      when(() => request.headers).thenReturn({});
      final res = await githubWebhook()(handler)(context);
      expect(res.statusCode, equals(HttpStatus.unauthorized));
    });

    test('Unauthorized when invalid signature header', () async {
      when(() => request.uri).thenReturn(
        Uri.parse('http://github.example.com/'),
      );
      when(() => configService.config).thenReturn(
        AppConfig(
          redisHost: '',
          subdomains: {
            'github': const SubdomainConfig(
              url: 'testing',
              secret: 'invalid',
            ),
          },
          logging: const LoggingConfig.defaultConfig(),
        ),
      );
      when(() => request.headers).thenReturn({hubSignature: 'invalid'});
      when(() => request.body()).thenAnswer(
        (_) async => 'invalid',
      );
      final res = await githubWebhook()(handler)(context);
      expect(res.statusCode, equals(HttpStatus.unauthorized));
    });

    test('Forwards to upstream', () async {
      const secret = "It's a Secret to Everybody";
      const payload = 'Hello, World!';
      const expectedSignature =
          '757107ea0eb2509fc211221cce984b8a37570b6d7586c22c46f4379c8b043e17';
      when(() => request.uri).thenReturn(
        Uri.parse('http://github.example.com/'),
      );
      when(() => configService.config).thenReturn(
        AppConfig(
          redisHost: '',
          subdomains: {
            'github': const SubdomainConfig(
              url: 'http://example.com',
              secret: secret,
            ),
          },
          logging: const LoggingConfig.defaultConfig(),
        ),
      );
      when(() => request.headers).thenReturn({hubSignature: expectedSignature});
      when(() => request.body()).thenAnswer(
        (_) async => payload,
      );
      when(() => forward.toUpstream(context, any(), body: any(named: 'body')))
          .thenAnswer((_) async => Response(body: upstreamResponseBody));
      final res = await githubWebhook()(handler)(context);
      expect(res.statusCode, equals(HttpStatus.ok));
      final body = await res.body();
      expect(body, upstreamResponseBody);
    });
  });
}
