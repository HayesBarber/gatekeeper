import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/challenge/verify.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  group('POST /challenge/verify', () {
    test('responds with a 200 and greeting.', () async {
      final context = _MockRequestContext();
      when(() => context.request).thenReturn(
        Request(
          HttpMethod.post.value,
          Uri.parse('http://localhost/challenge/verify'),
        ),
      );

      final response = route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.body(), completion(equals('This is a new route!')));
    });
  });
}
