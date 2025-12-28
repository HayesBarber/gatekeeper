import 'package:dart_frog/dart_frog.dart';

Middleware requiredHeaders() {
  return (Handler handler) {
    return (RequestContext context) async {
      return handler(context);
    };
  };
}
