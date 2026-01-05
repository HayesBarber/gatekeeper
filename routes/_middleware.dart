import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/config/yaml_config_service.dart';
import 'package:gatekeeper/logging/logger.dart';
import 'package:gatekeeper/middleware/api_key_provider.dart';
import 'package:gatekeeper/middleware/client_id_provider.dart';
import 'package:gatekeeper/middleware/cookie_provider.dart';
import 'package:gatekeeper/middleware/github_webhook.dart';
import 'package:gatekeeper/middleware/request_logger.dart' as request_logger;
import 'package:gatekeeper/middleware/subdomain_gatekeeper.dart';
import 'package:gatekeeper/middleware/subdomain_provider.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:gatekeeper/types/signature_verifier.dart';
import 'package:gatekeeper/util/forward_to_upstream.dart';

final _redis = ShorebirdRedisClient.instance();
final _config = YamlConfigService.instance();
final _logger = Logger.instance();
final _forward = Forward();

Handler middleware(Handler handler) {
  return handler
      .use(subdomainGatekeeper())
      .use(githubWebhook())
      .use(request_logger.requestLogger(_logger))
      .use(subdomainProvider())
      .use(apiKeyProvider())
      .use(clientIdProvider())
      .use(cookieProvider())
      .use(provider<SignatureVerifier>((_) => ECCKeyPair.verifySignatureStatic))
      .use(provider<Forward>((_) => _forward))
      .use(provider<ConfigService>((_) => _config))
      .use(provider<RedisClientBase>((_) => _redis));
}
