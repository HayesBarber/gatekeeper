import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/app_config.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/config/subdomain_config.dart';
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

    Response handler(context) {
      return Response(body: fallthroughResponseBody);
    }

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
        ),
      );
      final res = await githubWebhook()(handler)(context);

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
        ),
      );
      final res = await githubWebhook()(handler)(context);

      final body = await res.body();
      expect(body, fallthroughResponseBody);
    });

    test('Unauthorized when no signature header', () async {});

    test('Unauthorized when invalid signature header', () async {});

    test('Forwards to upstream', () async {});
  });
}
