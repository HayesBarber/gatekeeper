import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/challenge/verify.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

void main() {
  group('POST /challenge/verify', () {});

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
