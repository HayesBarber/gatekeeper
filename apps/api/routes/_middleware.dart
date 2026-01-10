import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/middleware/auth_token_provider.dart';
import 'package:gatekeeper/middleware/cookie_provider.dart';
import 'package:gatekeeper/middleware/github_webhook.dart';
import 'package:gatekeeper/middleware/request_logger.dart' as request_logger;
import 'package:gatekeeper/middleware/subdomain_gatekeeper.dart';
import 'package:gatekeeper/middleware/subdomain_provider.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:gatekeeper/util/forward_to_upstream.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart';
import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';

import '../main.dart';

final _redis = ShorebirdRedisClient.instance();
final _logger = Logger.instance();
final _forward = Forward();

Handler middleware(Handler handler) {
  return handler
      .use(subdomainGatekeeper())
      .use(githubWebhook())
      .use(request_logger.requestLogger(_logger))
      .use(subdomainProvider())
      .use(authTokenProvider())
      .use(cookieProvider())
      .use(provider<SignatureVerifier>((_) => ECCKeyPair.verifySignatureStatic))
      .use(provider<Forward>((_) => _forward))
      .use(provider<ConfigService>((_) => configService))
      .use(provider<RedisClientBase>((_) => _redis));
}
