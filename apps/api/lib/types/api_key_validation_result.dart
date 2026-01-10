import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart';

enum ApiKeyValidationError {
  noApiKey,
  apiKeyNotFound,
  apiKeyInvalid,
  apiKeyExpired,
}

class ApiKeyValidationResult {
  const ApiKeyValidationResult._({
    required this.isValid,
    this.errorResponse,
    this.storedApiKey,
    this.error,
  });

  factory ApiKeyValidationResult.success(
    ChallengeVerificationResponse storedApiKey,
  ) {
    return ApiKeyValidationResult._(
      isValid: true,
      storedApiKey: storedApiKey,
    );
  }

  factory ApiKeyValidationResult.failure({
    required ApiKeyValidationError error,
    required Response errorResponse,
  }) {
    return ApiKeyValidationResult._(
      isValid: false,
      errorResponse: errorResponse,
      error: error,
    );
  }

  factory ApiKeyValidationResult.noApiKey() {
    return ApiKeyValidationResult.failure(
      error: ApiKeyValidationError.noApiKey,
      errorResponse: Response(statusCode: HttpStatus.unauthorized),
    );
  }

  factory ApiKeyValidationResult.notFound() {
    return ApiKeyValidationResult.failure(
      error: ApiKeyValidationError.apiKeyNotFound,
      errorResponse: Response(statusCode: HttpStatus.forbidden),
    );
  }

  factory ApiKeyValidationResult.invalid() {
    return ApiKeyValidationResult.failure(
      error: ApiKeyValidationError.apiKeyInvalid,
      errorResponse: Response(statusCode: HttpStatus.forbidden),
    );
  }

  factory ApiKeyValidationResult.expired() {
    return ApiKeyValidationResult.failure(
      error: ApiKeyValidationError.apiKeyExpired,
      errorResponse: Response(statusCode: HttpStatus.forbidden),
    );
  }
  final bool isValid;
  final Response? errorResponse;
  final ChallengeVerificationResponse? storedApiKey;
  final ApiKeyValidationError? error;
}
