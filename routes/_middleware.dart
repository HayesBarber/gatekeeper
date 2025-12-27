import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';

final _redis = ShorebirdRedisClient();

Handler middleware(Handler handler) {
  return handler.use(provider<RedisClientBase>((_) => _redis));
}
