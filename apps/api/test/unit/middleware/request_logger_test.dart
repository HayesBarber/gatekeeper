import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/logging/logger.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
import 'package:gatekeeper/middleware/request_logger.dart' as gl;
import 'package:gatekeeper/middleware/subdomain_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockLogger extends Mock implements Logger {}

class _MockWideEvent extends Mock implements we.WideEvent {}

class _FakeWideEvent extends Fake implements we.WideEvent {}

class _MockSubdomainContext extends Mock implements SubdomainContext {}

void main() {
  group('Request logger middleware', () {
    late _MockRequestContext context;
    late _MockRequest request;
    late _MockLogger logger;
    late _MockWideEvent wideEvent;
    late _MockSubdomainContext subdomainContext;

    const responseBody = 'hello world';

    Response handler(context) {
      return Response(body: responseBody);
    }

    setUpAll(() {
      registerFallbackValue(Uri.parse('http://example.com/'));
      registerFallbackValue(_FakeWideEvent());
    });

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      logger = _MockLogger();
      wideEvent = _MockWideEvent();
      subdomainContext = _MockSubdomainContext();

      when(() => context.request).thenReturn(request);
      when(() => context.provide<we.WideEvent>(any())).thenReturn(context);
      when(() => context.read<we.WideEvent>()).thenReturn(wideEvent);
      when(() => context.read<SubdomainContext>()).thenReturn(subdomainContext);
      when(() => subdomainContext.subdomain).thenReturn('api');
      when(() => logger.generateRequestId()).thenReturn('test-123');
      when(() => wideEvent.requestId).thenReturn('test-123');
    });

    test('Creates wide event and logs on successful response', () async {
      when(() => request.uri)
          .thenReturn(Uri.parse('http://api.example.com/test'));
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.headers).thenReturn({
        userAgent: 'test-agent',
        forwardedFor: '192.168.1.1',
        contentLength: '100',
      });

      final middleware = gl.requestLogger(logger);
      final response = await middleware(handler)(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.body();
      expect(body, equals(responseBody));

      verify(() => logger.generateRequestId()).called(1);
      verify(() => logger.emitEvent(any())).called(1);
    });

    test('Creates wide event with minimal headers', () async {
      when(() => request.uri).thenReturn(Uri.parse('http://example.com/test'));
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => request.headers).thenReturn({});

      final middleware = gl.requestLogger(logger);
      final response = await middleware(handler)(context);

      expect(response.statusCode, equals(HttpStatus.ok));

      verify(() => logger.generateRequestId()).called(1);
      verify(() => logger.emitEvent(any())).called(1);
    });

    test('Logs error context when handler throws', () async {
      const errorMessage = 'Something went wrong';

      when(() => request.uri).thenReturn(Uri.parse('http://example.com/test'));
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.headers).thenReturn({});

      Response throwingHandler(context) {
        throw Exception(errorMessage);
      }

      final middleware = gl.requestLogger(logger);

      expect(
        () async => await middleware(throwingHandler)(context),
        throwsException,
      );

      verify(() => logger.generateRequestId()).called(1);
      verify(() => logger.emitEvent(any())).called(1);
    });

    test('Provides WideEvent to downstream handlers', () async {
      when(() => request.uri).thenReturn(Uri.parse('http://example.com/test'));
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.headers).thenReturn({});

      Response contextAwareHandler(RequestContext context) {
        final event = context.read<we.WideEvent>();
        expect(event, isNotNull);
        expect(event.requestId, equals('test-123'));
        return Response(body: responseBody);
      }

      final middleware = gl.requestLogger(logger);
      final response = await middleware(contextAwareHandler)(context);

      expect(response.statusCode, equals(HttpStatus.ok));

      verify(() => logger.generateRequestId()).called(1);
      verify(() => logger.emitEvent(any())).called(1);
    });
  });
}
