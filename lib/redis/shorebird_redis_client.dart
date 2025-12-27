import 'package:gatekeeper/redis/redis_client.dart';
import 'package:shorebird_redis_client/shorebird_redis_client.dart';

class ShorebirdRedisClient implements RedisClientBase {
  factory ShorebirdRedisClient() => _instance;

  ShorebirdRedisClient._internal();
  static final ShorebirdRedisClient _instance =
      ShorebirdRedisClient._internal();

  RedisClient? _client;
  bool _connected = false;

  RedisClient _getClient() {
    if (_client == null || !_connected) {
      throw StateError(
        'ShorebirdRedisClient not connected. Call connect() first.',
      );
    }
    return _client!;
  }

  @override
  Future<void> close() async {
    if (!_connected || _client == null) return;

    await _client!.close();
    _client = null;
    _connected = false;
  }

  @override
  Future<void> connect({String host = '127.0.0.1'}) async {
    if (_connected) return;

    final options = RedisSocketOptions(host: host);
    final client = RedisClient(socket: options);
    await client.connect();

    _client = client;
    _connected = true;
  }

  @override
  Future<void> delete({required String key}) => _getClient().delete(key: key);

  @override
  Future<String?> get({required String key}) => _getClient().get(key: key);

  @override
  Future<void> set({
    required String key,
    required String value,
    Duration? ttl,
  }) =>
      _getClient().set(
        key: key,
        value: value,
        ttl: ttl,
      );
}
