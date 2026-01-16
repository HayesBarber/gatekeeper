import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/middleware/auth_token_provider.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/types/auth_token_validation_result.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart' as gc;
import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';

class AuthTokenValidator {
  static Future<AuthTokenValidationResult> validateAuthToken({
    required String authToken,
    required String authTokenSource,
    required RedisClientBase redis,
  }) async {
    if (authToken.isEmpty) {
      return AuthTokenValidationResult.noAuthToken();
    }

    final storedAuthTokenData = await redis.get(
      ns: Namespace.authTokens,
      key: authToken,
    );
    if (storedAuthTokenData == null) {
      return AuthTokenValidationResult.notFound();
    }

    final storedAuthToken = gc.ChallengeVerificationResponse.decode(
      storedAuthTokenData,
    );

    if (!CryptoUtils.constantTimeCompare(
      authToken,
      storedAuthToken.authToken,
    )) {
      return AuthTokenValidationResult.invalid();
    }

    if (storedAuthToken.expiresAt.isBefore(DateTime.now())) {
      return AuthTokenValidationResult.expired();
    }

    return AuthTokenValidationResult.success(storedAuthToken);
  }

  static Future<AuthTokenValidationResult> validateAuthTokenContext({
    required RequestContext context,
  }) async {
    final authTokenContext = context.read<AuthTokenContext>();
    if (!authTokenContext.authTokenFound) {
      return AuthTokenValidationResult.noAuthToken();
    }

    final redis = context.read<RedisClientBase>();
    final result = await validateAuthToken(
      authToken: authTokenContext.authToken!,
      authTokenSource: authTokenContext.source!,
      redis: redis,
    );

    return result;
  }
}
