enum Namespace {
  users(key: 'users'),
  challenges(key: 'challenges', ttl: Duration(minutes: 5)),
  apiKeys(key: 'api_keys', ttl: Duration(minutes: 5));

  const Namespace({required this.key, this.ttl});

  final String key;
  final Duration? ttl;

  int ttlSeconds() => ttl != null ? ttl!.inSeconds : 1;
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
  Future<void> close();

  String redisKey(Namespace ns, String key) {
    return '${ns.key}:$key';
  }
}
