import '../models/app_config.dart';

/// Abstract interface for configuration services.
abstract class ConfigService {
  /// Gets the current application configuration.
  AppConfig get config;

  /// Reloads the configuration from the source.
  Future<void> reload();
}
