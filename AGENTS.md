# AGENTS.md

This file contains instructions for agentic coding agents working in the gatekeeper repository.

## Project Overview

Gatekeeper is a Dart Frog-based API gateway that provides subdomain routing, API key validation, and request forwarding. It's currently being migrated from FastAPI to Dart Frog.

## Build, Test, and Lint Commands

### Core Commands
```bash
# Install dependencies
dart pub get

# Run the development server
dart_frog dev

# Build for production
dart_frog build

# Analyze code for issues
dart analyze

# Run all tests
dart test

# Run tests with coverage
dart test --coverage coverage

# Lint (dart analyze with strict warnings)
dart analyze --fatal-warnings
```

### Single Test Execution
```bash
# Run a specific test file
dart test test/unit/middleware/api_key_validator_test.dart

# Run tests by name pattern
dart test --name "validateApiKeyContext"

# Run tests in a directory
dart test test/unit/middleware/

# Run integration tests only
dart test test/integration/

# Run unit tests only
dart test test/unit/
```

### Testing with tool/test.sh
For comprehensive testing including integration tests with real services, use the test script:

```bash
# Run unit tests only (no external dependencies)
./tool/test.sh unit    # or ./tool/test.sh ut

# Run integration tests (sets up Redis, servers, and environment)
./tool/test.sh integration    # or ./tool/test.sh it

# Run all tests (unit + integration)
./tool/test.sh all    # default
```

The test script handles:
- Redis connection and key generation
- Server startup (gatekeeper, echo servers)
- Environment variable setup
- Automatic cleanup on exit

### Development Workflow
```bash
# Start development server with hot reload
dart_frog dev

# Run tests in watch mode
dart test --reporter=compact

# Check formatting (if dart format is used)
dart format --set-exit-if-changed .

# Update dependencies
dart pub upgrade
```

## Code Style Guidelines

### Imports
- Order imports: dart libraries → package imports → local imports
- Use absolute imports for packages, relative for local files
- Group related imports with blank lines between groups
- No unused imports - `dart analyze` will catch these

```dart
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/yaml_config_service.dart';

import '../util/api_key_validator.dart';
import '../types/api_key_validation_result.dart';
```

### Formatting and Structure
- Follow Dart Frog conventions for route handlers and middleware
- Use `package:dart_frog_lint/recommended.yaml` (already configured)
- Keep files focused and reasonably sized
- Use meaningful variable and function names

### Types and Null Safety
- All code must be null-safe (Dart 3.0+)
- Prefer explicit type annotations for public APIs
- Use `const` for compile-time constants
- Non-nullable types by default, use `?` for nullable types

```dart
// Good
class ApiKeyValidator {
  static Future<ApiKeyValidationResult> validateApiKey({
    required String apiKey,
    required RedisClientBase redis,
  }) async {
    // implementation
  }
}

// Avoid implicit types in public APIs
Future<Map<String, dynamic>> processRequest(RequestContext context) async { // Bad
```

### Naming Conventions
- **Classes**: PascalCase (e.g., `ApiKeyValidator`, `SubdomainGatekeeper`)
- **Variables/Methods**: camelCase (e.g., `validateApiKey`, `subdomainContext`)
- **Constants**: SCREAMING_SNAKE_CASE for top-level constants (e.g., `DEFAULT_TIMEOUT`)
- **Files**: snake_case.dart (e.g., `api_key_validator.dart`)
- **Directories**: snake_case for consistency with Dart ecosystem

### Error Handling
- Use custom result types for validation operations (see `ApiKeyValidationResult`)
- Return specific error responses with appropriate HTTP status codes
- Use `try-catch` blocks only when necessary, prefer Result pattern
- Log errors using the configured logger

```dart
// Prefer this pattern
static Future<ApiKeyValidationResult> validateApiKey({...}) async {
  if (apiKey.isEmpty) {
    return ApiKeyValidationResult.noApiKey();
  }
  // validation logic
  return ApiKeyValidationResult.success(storedApiKey);
}

// Over try-catch when not needed
```

### Testing Conventions
- Use `mocktail` for mocking (already in dependencies)
- Arrange-Act-Assert pattern in tests
- Descriptive test names that explain the scenario
- Group related tests with `group()`
- Use `setUp()` for common initialization

```dart
void main() {
  group('ApiKeyValidator', () {
    late MockRequestContext mockContext;
    
    setUp(() {
      mockContext = MockRequestContext();
    });

    test('returns noApiKey when API key context has no key', () async {
      // Arrange
      when(() => mockContext.read<ApiKeyContext>()).thenReturn(
        const ApiKeyContext(apiKey: null, source: null),
      );
      
      // Act
      final result = await ApiKeyValidator.validateApiKeyContext(
        context: mockContext,
      );
      
      // Assert
      expect(result.isValid, isFalse);
      expect(result.error, equals(ApiKeyValidationError.noApiKey));
    });
  });
}
```

### Configuration
- Configuration loaded from `gatekeeper.yaml` using `YamlConfigService`
- Use environment variables for secrets (see `{{GITHUB_WEBHOOK_SECRET}}`)
- Configuration classes should be immutable
- Validate configuration on startup

### Middleware Patterns
- Middleware should follow Dart Frog conventions
- Use `context.read<T>()` to access dependencies
- Return early for error conditions
- Forward to upstream services when validation passes

### Redis Integration
- Use `ShorebirdRedisClient` for Redis operations
- Namespace keys appropriately (see `Namespace.apiKeys`)
- Handle Redis failures gracefully
- Use proper encoding/decoding for stored data

## Architecture Notes

- **Routes**: In `routes/` directory following Dart Frog structure
- **Middleware**: In `lib/middleware/` for cross-cutting concerns  
- **DTOs**: In `lib/dto/` for data transfer objects
- **Types**: In `lib/types/` for custom type definitions
- **Utils**: In `lib/util/` for helper functions and extensions
- **Tests**: Mirror the `lib/` structure in `test/`

## Important Constraints

- Always run `dart analyze` before committing - warnings are treated as errors
- Tests must pass before merging
- Follow the existing patterns rather than introducing new frameworks
- Security is critical - never expose secrets or API keys in logs or responses
- Use constant-time comparison for sensitive data (see `CryptoUtils.constantTimeCompare`)