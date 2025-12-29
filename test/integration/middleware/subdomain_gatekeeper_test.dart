import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:test/test.dart';

import '../util/test_env.dart';

void main() {
  group('Subdomain gatekeeper middleware', () {
    late RedisClientBase redis;

    setUpAll(() async {
      redis = await ShorebirdRedisClient.connect(
        host: TestEnv.redisHost,
      );
    });

    tearDown(() async {
      await redis.delete(
        ns: Namespace.challenges,
        key: TestEnv.clientId,
      );
      await redis.delete(
        ns: Namespace.apiKeys,
        key: TestEnv.clientId,
      );
    });

    tearDownAll(() async {
      await redis.close();
    });

    test('returns 200 healty when no subdomain matches', () async {});

    test('returns 200 healty when client ID header is missing', () async {});

    test('returns 403 for missing api key', () async {});

    test('returns 403 for invalid api key', () async {});

    test('returns 200 from upstream when api key is valid', () async {});
  });
}
