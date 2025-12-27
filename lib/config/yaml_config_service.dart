import 'dart:io';
import 'package:gatekeeper/config/app_config.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:yaml/yaml.dart';

class YamlConfigService implements ConfigService {
  YamlConfigService._(this._config);

  static YamlConfigService? _instance;

  final AppConfig _config;

  static YamlConfigService instance() {
    if (_instance == null) {
      throw StateError('YamlConfigService not initialized. Call load() first.');
    }
    return _instance!;
  }

  static Future<YamlConfigService> load({
    required String path,
  }) async {
    if (_instance != null) {
      return _instance!;
    }

    YamlMap? doc;

    final file = File(path);
    if (file.existsSync()) {
      final contents = await file.readAsString();
      final parsed = loadYaml(contents);
      if (parsed is YamlMap) {
        doc = parsed;
      }
    }

    final redis = doc?['redis'];
    final redisHost = redis is YamlMap
        ? redis['host'] as String? ?? '127.0.0.1'
        : '127.0.0.1';

    final clientIdHeader =
        doc?['client_id_header'] as String? ?? 'x-requestor-id';

    final config = AppConfig(
      redisHost: redisHost,
      clientIdHeader: clientIdHeader,
    );

    _instance = YamlConfigService._(config);
    return _instance!;
  }

  @override
  AppConfig get config => _config;
}
