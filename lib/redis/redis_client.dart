enum Namespace {
  devices(key: 'devices'),
  challenges(key: 'challenges'),
  apiKeys(key: 'api_keys');

  const Namespace({required this.key});

  final String key;
}

abstract class RedisClientBase {
  Future<String?> get({
    required Namespace ns,
    required String key,
  });
  Future<void> delete({
    required Namespace ns,
    required String key,
  });
  Future<void> set({
    required Namespace ns,
    required String key,
    required String value,
    Duration? ttl,
  });
  Future<List<T>> getAll<T>({
    required Namespace ns,
    required T Function(String) parser,
  });
  Future<void> deleteAll({
    required Namespace ns,
  });
  Future<void> close();

  String redisKey(Namespace ns, String key) {
    return '${ns.key}:$key';
  }
}
