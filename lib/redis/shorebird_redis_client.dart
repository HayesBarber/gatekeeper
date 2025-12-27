import 'package:gatekeeper/redis/redis_client.dart';
import 'package:shorebird_redis_client/shorebird_redis_client.dart';

class ShorebirdRedisClient implements RedisClientBase {
  ShorebirdRedisClient._(this._client);

  static ShorebirdRedisClient? _instance;

  final RedisClient _client;

  static ShorebirdRedisClient instance() {
    if (_instance == null) {
      throw StateError(
        'ShorebirdRedisClient not connected. Call connect() first.',
      );
    }
    return _instance!;
  }

  Future<void> close() async {
    await _client.close();
  }

  static Future<ShorebirdRedisClient> connect({
    String host = '127.0.0.1',
  }) async {
    final options = RedisSocketOptions(host: host);
    final client = RedisClient(socket: options);
    await client.connect();

    _instance = ShorebirdRedisClient._(client);
    return _instance!;
  }

  @override
  Future<void> delete({required String key}) => _client.delete(key: key);

  @override
  Future<String?> get({required String key}) => _client.get(key: key);

  @override
  Future<void> set({
    required String key,
    required String value,
    Duration? ttl,
  }) =>
      _client.set(
        key: key,
        value: value,
        ttl: ttl,
      );
}
