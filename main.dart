import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'util/redis.dart';

Future<void> init(InternetAddress ip, int port) async {
  await Redis().connect();
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  return serve(handler, ip, port);
}
