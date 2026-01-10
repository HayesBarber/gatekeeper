import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/middleware/subdomain_provider.dart';
import 'package:gatekeeper/util/extensions.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart' as gc;

Middleware requestLogger(gc.Logger logger) {
  return (handler) {
    return (context) async {
      final requestId = logger.generateRequestId();
      final startTime = DateTime.now();

      final request = context.request;
      final subdomainContext = context.read<SubdomainContext>();

      final wideEvent = gc.WideEvent(
        requestId: requestId,
        request: gc.RequestContext(
          method: request.method.value,
          path: request.uri.path,
          timestamp: startTime.millisecondsSinceEpoch,
          subdomain: subdomainContext.subdomain,
          userAgent: request.headers[gc.userAgent],
          clientIp:
              request.headers[gc.forwardedFor] ?? request.headers[gc.realIp],
          contentLength: request.headers[gc.contentLength] != null
              ? int.tryParse(request.headers[gc.contentLength]!)
              : null,
        ),
      );

      final contextWithProvider = context.provide<gc.WideEvent>(
        () => wideEvent,
      );

      try {
        final response = await handler(contextWithProvider);

        final duration = DateTime.now().since(startTime);

        wideEvent.response = gc.ResponseContext(
          durationMs: duration,
          statusCode: response.statusCode,
          contentLength: response.headers[gc.contentLength] != null
              ? int.tryParse(response.headers[gc.contentLength]!)
              : null,
        );

        logger.emitEvent(wideEvent);

        return response;
      } catch (error) {
        final duration = DateTime.now().since(startTime);

        wideEvent
          ..response = gc.ResponseContext(
            durationMs: duration,
            statusCode: 500,
          )
          ..error = gc.ErrorContext(
            type: error.runtimeType.toString(),
            code: 'unhandled_exception',
            retriable: false,
            context: {'message': error.toString()},
          );

        logger.emitEvent(wideEvent);
        rethrow;
      }
    };
  };
}
