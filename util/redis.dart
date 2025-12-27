import 'package:shorebird_redis_client/shorebird_redis_client.dart';

class Redis {
  factory Redis() => _instance;

  Redis._internal();
  static final Redis _instance = Redis._internal();

  RedisClient? _client;
  bool _connected = false;

  RedisClient get client {
    if (_client == null || !_connected) {
      throw StateError('RedisService not connected. Call connect() first.');
    }
    return _client!;
  }

  Future<void> close() async {
    if (!_connected || _client == null) return;

    await _client!.close();
    _client = null;
    _connected = false;
  }

  Future<void> connect() async {
    if (_connected) return;

    final client = RedisClient();
    await client.connect();

    _client = client;
    _connected = true;
  }

  Future<void> Function({required String key}) delete(String key) =>
      client.delete;

  Future<String?> Function({required String key}) get(String key) => client.get;

  Future<void> Function({
    required String key,
    required String value,
    Duration? ttl,
  }) set(String key, String value) => client.set;
}
