import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';

Middleware sameOrigin() {
  return (handler) {
    return (context) async {
      final config = context.read<ConfigService>().config;
      final domain = config.domain;
      final headers = context.request.headers;
      final origin = headers['origin'];

      if (origin == null) {
        return handler(context);
      }

      if (!origin.contains(domain)) {
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

      return handler(context);
    };
  };
}
