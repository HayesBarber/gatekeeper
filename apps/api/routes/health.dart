import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.get => Response(body: 'healthy'),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}
