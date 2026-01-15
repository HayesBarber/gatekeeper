import 'package:dart_frog/dart_frog.dart';

Middleware sameOrigin() {
  return (handler) {
    return (context) async {
      return handler(context);
    };
  };
}
