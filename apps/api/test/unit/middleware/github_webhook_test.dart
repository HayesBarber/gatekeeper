import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/middleware/github_webhook.dart';
import 'package:gatekeeper/middleware/subdomain_provider.dart';
import 'package:gatekeeper/util/forward_to_upstream.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart' as gc;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockConfigService extends Mock implements ConfigService {}

class _MockSubdomainContext extends Mock implements SubdomainContext {}

class _MockForward extends Mock implements Forward {}

class _MockWideEvent extends Mock implements gc.WideEvent {}

void main() {
  group('GitHub webhook middleware', () {
    late _MockRequestContext context;
    late _MockRequest request;
    late _MockConfigService configService;
    late _MockForward forward;
    late _MockWideEvent wideEvent;
    late _MockSubdomainContext subdomainContext;

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
      wideEvent = _MockWideEvent();
      subdomainContext = _MockSubdomainContext();

      when(() => context.request).thenReturn(request);
      when(() => context.read<ConfigService>()).thenReturn(configService);
      when(() => context.read<Forward>()).thenReturn(forward);
      when(() => context.read<gc.WideEvent>()).thenReturn(wideEvent);
      when(() => context.read<SubdomainContext>()).thenReturn(subdomainContext);

      when(() => subdomainContext.subdomain).thenReturn('api');
      when(() => subdomainContext.hasConfig).thenReturn(false);
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
        AppConfig.fromJson({
          'redis': {
            'host': '127.0.0.1',
            'ttl': {'challenges': '30s', 'auth_tokens': '5m'},
          },
          'subdomains': {
            'github': {
              'url': 'testing',
            },
          },
          'logging': {'enabled': true},
          'domain': 'test-domain.com',
        }),
      );
      final res = await githubWebhook()(handler)(context);
      expect(res.statusCode, equals(HttpStatus.ok));
      final body = await res.body();
      expect(body, fallthroughResponseBody);
    });

    test('Unauthorized when no signature header', () async {
      final subdomainContext = context.read<SubdomainContext>();

      when(() => request.uri).thenReturn(
        Uri.parse('http://github.example.com/'),
      );
      when(() => subdomainContext.subdomain).thenReturn('github');
      when(() => subdomainContext.hasConfig).thenReturn(true);
      when(() => subdomainContext.config).thenReturn(
        SubdomainConfig(
          url: 'testing',
          secret: 'invalid',
        ),
      );
      when(() => configService.config).thenReturn(
        AppConfig.fromJson({
          'redis': {
            'host': '127.0.0.1',
            'ttl': {'challenges': '30s', 'auth_tokens': '5m'},
          },
          'subdomains': {
            'github': SubdomainConfig(
              url: 'testing',
              secret: 'invalid',
            ),
          },
          'logging': {'enabled': true},
          'domain': 'test-domain.com',
        }),
      );
      when(() => request.headers).thenReturn({});
      final res = await githubWebhook()(handler)(context);
      expect(res.statusCode, equals(HttpStatus.unauthorized));
    });

    test('Unauthorized when invalid signature header', () async {
      final subdomainContext = context.read<SubdomainContext>();

      when(() => request.uri).thenReturn(
        Uri.parse('http://github.example.com/'),
      );
      when(() => subdomainContext.subdomain).thenReturn('github');
      when(() => subdomainContext.hasConfig).thenReturn(true);
      when(() => subdomainContext.config).thenReturn(
        SubdomainConfig(
          url: 'testing',
          secret: 'invalid',
        ),
      );
      when(() => configService.config).thenReturn(
        AppConfig.fromJson({
          'redis': {
            'host': '127.0.0.1',
            'ttl': {'challenges': '30s', 'auth_tokens': '5m'},
          },
          'subdomains': {
            'github': {
              'url': 'testing',
              'secret': 'invalid',
            },
          },
          'logging': {'enabled': true},
          'domain': 'test-domain.com',
        }),
      );
      when(() => request.headers).thenReturn({gc.hubSignature: 'invalid'});
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
      final subdomainContext = context.read<SubdomainContext>();

      when(() => request.uri).thenReturn(
        Uri.parse('http://github.example.com/'),
      );
      when(() => subdomainContext.subdomain).thenReturn('github');
      when(() => subdomainContext.hasConfig).thenReturn(true);
      when(() => subdomainContext.config).thenReturn(
        SubdomainConfig(
          url: 'testing',
          secret: secret,
        ),
      );
      when(() => configService.config).thenReturn(
        AppConfig.fromJson({
          'redis': {
            'host': '127.0.0.1',
            'ttl': {'challenges': '30s', 'auth_tokens': '5m'},
          },
          'subdomains': {
            'github': {
              'url': 'http://example.com',
              'secret': secret,
            },
          },
          'logging': {'enabled': true},
          'domain': 'test-domain.com',
        }),
      );
      when(() => request.headers).thenReturn({
        gc.hubSignature: expectedSignature,
      });
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
