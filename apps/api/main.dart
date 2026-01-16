import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';

final configService = JsonConfigService('gatekeeper.json');

Future<void> init(InternetAddress ip, int port) async {
  await configService.reload();

  await ShorebirdRedisClient.connect(
    host: configService.config.redis.host,
  );
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  return serve(handler, ip, port, poweredByHeader: null);
}
