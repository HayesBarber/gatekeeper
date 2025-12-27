import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/redis/redis_client.dart';

Middleware redisProvider(RedisClientBase redis) {
  return provider<RedisClientBase>((_) => redis);
}
