import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/config/yaml_config_service.dart';
import 'package:gatekeeper/middleware/github_webhook.dart';
import 'package:gatekeeper/middleware/subdomain_gatekeeper.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:gatekeeper/types/signature_verifier.dart';
import 'package:gatekeeper/util/forward_to_upstream.dart';

final _redis = ShorebirdRedisClient.instance();
final _config = YamlConfigService.instance();
final _forward = Forward();

Handler middleware(Handler handler) {
  return handler
      .use(subdomainGatekeeper())
      .use(githubWebhook())
      .use(provider<SignatureVerifier>((_) => ECCKeyPair.verifySignatureStatic))
      .use(provider<Forward>((_) => _forward))
      .use(provider<ConfigService>((_) => _config))
      .use(provider<RedisClientBase>((_) => _redis));
}
