import 'dart:convert';
import 'dart:io';
import '../services/config_service.dart';
import '../models/app_config.dart';
import '../exceptions/config_validation_exception.dart';
import '../utils/config_validator.dart';

/// JSON-based implementation of ConfigService with strict validation.
class JsonConfigService implements ConfigService {
  JsonConfigService(this.configPath);

  final String configPath;
  late AppConfig _config;

  @override
  AppConfig get config => _config;

  @override
  Future<void> reload() async {
    try {
      final file = File(configPath);
      if (!await file.exists()) {
        throw ConfigValidationException(
          'Configuration file not found: $configPath',
        );
      }

      final content = await file.readAsString();
      final Map<String, dynamic> jsonData =
          jsonDecode(content) as Map<String, dynamic>;

      // Validate the JSON structure before parsing
      ConfigValidator.validateAppConfig(jsonData);

      // Parse into strongly typed objects
      _config = AppConfig.fromJson(jsonData);
    } on FileSystemException catch (e) {
      throw ConfigValidationException(
        'Failed to read configuration file: ${e.message}',
      );
    } on FormatException catch (e) {
      throw ConfigValidationException('Invalid JSON format: ${e.message}');
    } on ConfigValidationException {
      // Re-throw validation exceptions as-is
      rethrow;
    } catch (e) {
      throw ConfigValidationException(
        'Unexpected error loading configuration: $e',
      );
    }
  }
}
