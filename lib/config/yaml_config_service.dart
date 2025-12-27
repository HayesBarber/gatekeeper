import 'dart:io';
import 'package:gatekeeper/config/app_config.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:yaml/yaml.dart';

class YamlConfigService implements ConfigService {
  YamlConfigService._(this._config);

  static YamlConfigService? _instance;
  static bool _initialized = false;

  final AppConfig _config;

  static Future<YamlConfigService> load({
    required String path,
  }) async {
    if (_initialized) {
      return _instance!;
    }

    final file = File(path);
    if (!file.existsSync()) {
      throw StateError('Config file not found: $path');
    }

    final doc = loadYaml(await file.readAsString()) as YamlMap;

    final config = AppConfig(
      redisUrl: doc['redis']['url'] as String,
    );

    _instance = YamlConfigService._(config);
    _initialized = true;

    return _instance!;
  }

  static YamlConfigService instance() {
    if (!_initialized || _instance == null) {
      throw StateError('YamlConfigService not initialized. Call load() first.');
    }
    return _instance!;
  }

  @override
  AppConfig get config => _config;
}
