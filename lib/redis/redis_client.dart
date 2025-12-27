abstract interface class RedisClientBase {
  Future<void> connect();
  Future<void> close();

  Future<String?> get({required String key});
  Future<void> delete({required String key});
  Future<void> set({
    required String key,
    required String value,
    Duration? ttl,
  });
}
