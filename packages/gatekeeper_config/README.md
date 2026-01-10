# Gatekeeper Config Package

A JSON-based configuration management package for Gatekeeper with strict validation and dependency injection support.

## Features

- **JSON-based configuration** using Dart's built-in `dart:convert`
- **Strict validation** with detailed error messages
- **Dependency injection** support (no singleton pattern)
- **DNS naming validation** for subdomains
- **Path validation** for blacklist entries
- **Duration parsing** with unit support (s, m, h, d)
- **Comprehensive test coverage**

## Usage

```dart
import 'package:gatekeeper_config/gatekeeper_config.dart';

// Create service instance
final configService = JsonConfigService('gatekeeper.json');
await configService.reload();

// Access configuration
final config = configService.config;
print(config.redis.host);
print(config.subdomains['api']?.url);
```

## Configuration Schema

See README.md for the complete JSON schema and validation rules.