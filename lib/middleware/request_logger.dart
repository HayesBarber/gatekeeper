import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/logging/logger.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
import 'package:gatekeeper/middleware/subdomain_provider.dart';
import 'package:gatekeeper/util/extensions.dart';

Middleware requestLogger(Logger logger) {
  return (handler) {
    return (context) async {
      final requestId = logger.generateRequestId();
      final startTime = DateTime.now();

      final request = context.request;
      final subdomainContext = context.read<SubdomainContext>();

      final wideEvent = we.WideEvent(
        requestId: requestId,
        request: we.RequestContext(
          method: request.method.value,
          path: request.uri.path,
          timestamp: startTime.millisecondsSinceEpoch,
          subdomain: subdomainContext.subdomain,
          userAgent: request.headers[userAgent],
          clientIp: request.headers[forwardedFor] ?? request.headers[realIp],
          contentLength: request.headers[contentLength] != null
              ? int.tryParse(request.headers[contentLength]!)
              : null,
          clientId: request.headers[headerRequestorId],
        ),
      );

      final contextWithProvider = context.provide<we.WideEvent>(
        () => wideEvent,
      );

      try {
        final response = await handler(contextWithProvider);

        final duration = DateTime.now().since(startTime);

        wideEvent.response = we.ResponseContext(
          durationMs: duration,
          statusCode: response.statusCode,
          contentLength: response.headers[contentLength] != null
              ? int.tryParse(response.headers[contentLength]!)
              : null,
        );

        logger.emitEvent(wideEvent);

        return response;
      } catch (error) {
        final duration = DateTime.now().since(startTime);

        wideEvent
          ..response = we.ResponseContext(
            durationMs: duration,
            statusCode: 500,
          )
          ..error = we.ErrorContext(
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
