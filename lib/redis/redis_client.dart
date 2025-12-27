abstract interface class RedisClientBase {
  Future<String?> get({required String key});
  Future<void> delete({required String key});
  Future<void> set({
    required String key,
    required String value,
    Duration? ttl,
  });
}
