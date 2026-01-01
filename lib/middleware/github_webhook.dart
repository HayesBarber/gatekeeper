import 'package:dart_frog/dart_frog.dart';

Middleware githubWebhook() {
  return (handler) {
    return (context) async {
      return handler(context);
    };
  };
}
