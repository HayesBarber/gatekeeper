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
    final doc = await _loadYamlFile(path);
    final config = _parseAppConfig(doc);

    _instance = YamlConfigService._(config);
    return _instance!;
  }

  @override
  AppConfig get config => _config;

  static Future<YamlMap?> _loadYamlFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;

    final contents = await file.readAsString();
    return _loadYamlString(contents);
  }

  static Future<YamlMap?> _loadYamlString(String contents) async {
    final parsed = loadYaml(contents);
    return parsed is YamlMap ? parsed : null;
  }

  static AppConfig _parseAppConfig(YamlMap? doc) {
    return AppConfig(
      redisHost: _getRedisHost(doc),
      clientIdHeader: _getClientIdHeader(doc),
      subdomainUpstreams: {},
    );
  }

  static String _getRedisHost(YamlMap? doc) {
    final redis = doc?['redis'];
    if (redis is YamlMap) {
      return redis['host'] as String? ?? '127.0.0.1';
    }
    return '127.0.0.1';
  }

  static String _getClientIdHeader(YamlMap? doc) {
    return doc?['client_id_header'] as String? ?? 'x-requestor-id';
  }
}
