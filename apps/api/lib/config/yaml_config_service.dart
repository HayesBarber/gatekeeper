import 'dart:io';
import 'package:gatekeeper/config/app_config.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/config/logging_config.dart';
import 'package:gatekeeper/config/redis_config.dart';
import 'package:gatekeeper/config/subdomain_config.dart';
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
      redis: _getRedisConfig(doc),
      subdomains: _getSubdomainUpstreams(doc),
      logging: _getLoggingConfig(doc),
      domain: _getDomain(doc),
    );
  }

  static String? _getDomain(YamlMap? doc) {
    return doc?['domain'] as String?;
  }

  static RedisConfig _getRedisConfig(YamlMap? doc) {
    final redis = doc?['redis'];
    if (redis is YamlMap) {
      final ttl = redis['ttl'] as YamlMap?;
      return RedisConfig(
        host: redis['host'] as String? ?? '127.0.0.1',
        challengesTtl: _parseDuration(ttl?['challenges'] as String?) ??
            const Duration(seconds: 30),
        apiKeysTtl: _parseDuration(ttl?['api_keys'] as String?) ??
            const Duration(minutes: 5),
      );
    }
    return const RedisConfig.defaultConfig();
  }

  static Duration? _parseDuration(String? value) {
    if (value == null || value.isEmpty) return null;

    final regex = RegExp(r'^(\d+)(s|m|h|d)?$');
    final match = regex.firstMatch(value.trim());
    if (match == null) return null;

    final number = int.parse(match.group(1)!);
    final unit = match.group(2) ?? 's';

    switch (unit) {
      case 's':
        return Duration(seconds: number);
      case 'm':
        return Duration(minutes: number);
      case 'h':
        return Duration(hours: number);
      case 'd':
        return Duration(days: number);
      default:
        return Duration(seconds: number);
    }
  }

  static Map<String, SubdomainConfig> _getSubdomainUpstreams(YamlMap? doc) {
    final subdomains = doc?['subdomains'];
    if (subdomains is YamlMap) {
      return Map.fromEntries(
        subdomains.entries.map((entry) {
          final key = entry.key.toString();
          final value = entry.value as YamlMap;
          return MapEntry(
            key,
            SubdomainConfig(
              url: value['url'] as String,
              blacklistedPaths: _parseBlacklistedPaths(value['blacklist']),
              secret: value['secret'] as String?,
            ),
          );
        }),
      );
    }
    return {};
  }

  static LoggingConfig _getLoggingConfig(YamlMap? doc) {
    final logging = doc?['logging'];
    if (logging is YamlMap) {
      return LoggingConfig(
        loggingEnabled: logging['enabled'] as bool? ?? true,
      );
    }
    return const LoggingConfig.defaultConfig();
  }

  static Map<String, List<String>>? _parseBlacklistedPaths(dynamic blacklist) {
    if (blacklist == null) return null;
    if (blacklist is! YamlMap) return null;

    final result = <String, List<String>>{};
    for (final entry in blacklist.entries) {
      final method = entry.key.toString();
      final paths = entry.value;

      if (paths is YamlList) {
        result[method] = paths.whereType<String>().toList();
      }
    }
    return result.isEmpty ? null : result;
  }
}
