import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/config/yaml_config_service.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:gatekeeper/types/signature_verifier.dart';

final _redis = ShorebirdRedisClient.instance();
final _config = YamlConfigService.instance();

Handler middleware(Handler handler) {
  return handler
      .use(provider<ConfigService>((_) => _config))
      .use(provider<SignatureVerifier>((_) => VerifySignature.verifySignature))
      .use(provider<RedisClientBase>((_) => _redis));
}
