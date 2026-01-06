import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/dto/challenge_verification_response.dart';
import 'package:gatekeeper/logging/wide_event.dart' as we;
import 'package:gatekeeper/middleware/api_key_provider.dart';
import 'package:gatekeeper/middleware/client_id_provider.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/types/api_key_validation_result.dart';
import 'package:gatekeeper/util/extensions.dart';

class ApiKeyValidator {
  static Future<ApiKeyValidationResult> validateApiKey({
    required String clientId,
    required String apiKey,
    required String apiKeySource,
    required RedisClientBase redis,
    required we.WideEvent eventBuilder,
  }) async {
    if (apiKey.isEmpty) {
      return ApiKeyValidationResult.noApiKey();
    }

    final storedApiKeyData = await redis.get(
      ns: Namespace.apiKeys,
      key: clientId,
    );
    if (storedApiKeyData == null) {
      return ApiKeyValidationResult.notFound();
    }

    final storedApiKey = ChallengeVerificationResponse.decode(storedApiKeyData);

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
    final eventBuilder = context.read<we.WideEvent>();
    final clientId = context.read<ClientIdContext>().clientId;
    if (clientId == null) {
      eventBuilder.authentication = we.AuthenticationContext(
        authDurationMs: 0,
        apiKeyPresent: false,
      );
      return ApiKeyValidationResult.noApiKey();
    }

    final apiKeyContext = context.read<ApiKeyContext>();
    if (!apiKeyContext.apiKeyFound) {
      eventBuilder.authentication = we.AuthenticationContext(
        authDurationMs: 0,
        apiKeyPresent: false,
      );
      return ApiKeyValidationResult.noApiKey();
    }

    final redis = context.read<RedisClientBase>();
    final start = DateTime.now();
    final result = await validateApiKey(
      clientId: clientId,
      apiKey: apiKeyContext.apiKey!,
      apiKeySource: apiKeyContext.source!,
      redis: redis,
      eventBuilder: eventBuilder,
    );

    if (!result.isValid) {
      eventBuilder.authentication = we.AuthenticationContext(
        authDurationMs: DateTime.now().since(start),
        apiKeyPresent: true,
        apiKeySource: apiKeyContext.source,
        apiKeyStored: result.storedApiKey != null,
        apiKeyValid: result.error != ApiKeyValidationError.apiKeyInvalid,
        keyExpired: result.error == ApiKeyValidationError.apiKeyExpired,
      );
    } else {
      eventBuilder.authentication = we.AuthenticationContext(
        authDurationMs: DateTime.now().since(start),
      );
    }

    return result;
  }
}
