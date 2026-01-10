import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/middleware/api_key_provider.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/types/api_key_validation_result.dart';
import 'package:gatekeeper/util/extensions.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart' as gc;
import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';

class ApiKeyValidator {
  static Future<ApiKeyValidationResult> validateApiKey({
    required String apiKey,
    required String apiKeySource,
    required RedisClientBase redis,
    required gc.WideEvent eventBuilder,
  }) async {
    if (apiKey.isEmpty) {
      return ApiKeyValidationResult.noApiKey();
    }

    final storedApiKeyData = await redis.get(
      ns: Namespace.apiKeys,
      key: apiKey,
    );
    if (storedApiKeyData == null) {
      return ApiKeyValidationResult.notFound();
    }

    final storedApiKey = gc.ChallengeVerificationResponse.decode(
      storedApiKeyData,
    );

    if (!CryptoUtils.constantTimeCompare(apiKey, storedApiKey.apiKey)) {
      return ApiKeyValidationResult.invalid();
    }

    if (storedApiKey.expiresAt.isBefore(DateTime.now())) {
      return ApiKeyValidationResult.expired();
    }

    return ApiKeyValidationResult.success(storedApiKey);
  }

  static Future<ApiKeyValidationResult> validateApiKeyContext({
    required RequestContext context,
  }) async {
    final eventBuilder = context.read<gc.WideEvent>();

    final apiKeyContext = context.read<ApiKeyContext>();
    if (!apiKeyContext.apiKeyFound) {
      eventBuilder.authentication = gc.AuthenticationContext(
        authDurationMs: 0,
        apiKeyPresent: false,
      );
      return ApiKeyValidationResult.noApiKey();
    }

    final start = DateTime.now();
    final redis = context.read<RedisClientBase>();
    final result = await validateApiKey(
      apiKey: apiKeyContext.apiKey!,
      apiKeySource: apiKeyContext.source!,
      redis: redis,
      eventBuilder: eventBuilder,
    );

    if (!result.isValid) {
      eventBuilder.authentication = gc.AuthenticationContext(
        authDurationMs: DateTime.now().since(start),
        apiKeyPresent: true,
        apiKeySource: apiKeyContext.source,
        apiKeyStored: result.storedApiKey != null,
        apiKeyValid: result.error != ApiKeyValidationError.apiKeyInvalid,
        keyExpired: result.error == ApiKeyValidationError.apiKeyExpired,
      );
    } else {
      eventBuilder.authentication = gc.AuthenticationContext(
        authDurationMs: DateTime.now().since(start),
      );
    }

    return result;
  }
}
