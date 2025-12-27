import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/config/yaml_config_service.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';

final _redis = ShorebirdRedisClient();
final _config = YamlConfigService.instance();

Handler middleware(Handler handler) {
  return handler
      .use(provider<ConfigService>((_) => _config))
      .use(provider<RedisClientBase>((_) => _redis));
}
