import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/middleware/github_webhook.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  group('GitHub webhook middleware', () {
    test('Falls through when no match', () async {
      Response handler(context) {
        return Response(body: 'hello world');
      }

      final request = Request.get(Uri.parse('http://localhost/'));
      final context = _MockRequestContext();
      when(() => context.request).thenReturn(request);

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
