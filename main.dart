import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';

Future<void> init(InternetAddress ip, int port) async {
  await ShorebirdRedisClient().connect();
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  return serve(handler, ip, port);
}
