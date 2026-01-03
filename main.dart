import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/yaml_config_service.dart';
import 'package:gatekeeper/logging/logger.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';

Future<void> init(InternetAddress ip, int port) async {
  final configService = await YamlConfigService.load(path: 'gatekeeper.yaml');

  Logger.init(
    loggingEnabled: configService.config.logging.loggingEnabled,
    slowRequestThresholdMs: configService.config.logging.slowRequestThresholdMs,
    successfulSampleRate: configService.config.logging.successfulSampleRate,
  );

  await ShorebirdRedisClient.connect(
    host: configService.config.redisHost,
  );
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  return serve(handler, ip, port, poweredByHeader: null);
}
