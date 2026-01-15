import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/middleware/same_origin.dart';

Handler middleware(Handler handler) {
  return handler.use(sameOrigin());
}
