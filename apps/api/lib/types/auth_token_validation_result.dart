import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart';

enum AuthTokenValidationError {
  noAuthToken,
  authTokenNotFound,
  authTokenInvalid,
  authTokenExpired,
}

class AuthTokenValidationResult {
  const AuthTokenValidationResult._({
    required this.isValid,
    this.errorResponse,
    this.storedAuthToken,
    this.error,
  });

  factory AuthTokenValidationResult.success(
    ChallengeVerificationResponse storedAuthToken,
  ) {
    return AuthTokenValidationResult._(
      isValid: true,
      storedAuthToken: storedAuthToken,
    );
  }

  factory AuthTokenValidationResult.failure({
    required AuthTokenValidationError error,
    required Response errorResponse,
  }) {
    return AuthTokenValidationResult._(
      isValid: false,
      errorResponse: errorResponse,
      error: error,
    );
  }

  factory AuthTokenValidationResult.noAuthToken() {
    return AuthTokenValidationResult.failure(
      error: AuthTokenValidationError.noAuthToken,
      errorResponse: Response(statusCode: HttpStatus.unauthorized),
    );
  }

  factory AuthTokenValidationResult.notFound() {
    return AuthTokenValidationResult.failure(
      error: AuthTokenValidationError.authTokenNotFound,
      errorResponse: Response(statusCode: HttpStatus.forbidden),
    );
  }

  factory AuthTokenValidationResult.invalid() {
    return AuthTokenValidationResult.failure(
      error: AuthTokenValidationError.authTokenInvalid,
      errorResponse: Response(statusCode: HttpStatus.forbidden),
    );
  }

  factory AuthTokenValidationResult.expired() {
    return AuthTokenValidationResult.failure(
      error: AuthTokenValidationError.authTokenExpired,
      errorResponse: Response(statusCode: HttpStatus.forbidden),
    );
  }
  final bool isValid;
  final Response? errorResponse;
  final ChallengeVerificationResponse? storedAuthToken;
  final AuthTokenValidationError? error;
}
