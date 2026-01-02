import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/middleware/github_webhook.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockConfigService extends Mock implements ConfigService {}

void main() {
  group('GitHub webhook middleware', () {
    late _MockRequestContext context;
    late _MockRequest request;
    late _MockConfigService configService;

    Response handler(context) {
      return Response(body: 'hello world');
    }

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      configService = _MockConfigService();

      when(() => context.request).thenReturn(request);
      when(() => request.uri).thenReturn(Uri.parse('http://localhost/'));
    });

    test('Falls through when no match', () async {
      final res = await githubWebhook()(handler)(context);

      final body = await res.body();
      expect(body, 'hello world');
    });

    test('Falls through when no subdomain config', () async {});

    test('Falls through when no secret', () async {});

    test('Unauthorized when no signature header', () async {});

    test('Unauthorized when invalid signature header', () async {});

    test('Forwards to upstream', () async {});
  });
}
