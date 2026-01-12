import 'dart:convert';

import 'package:gatekeeper_cli/src/models/cli_config.dart';
import 'package:gatekeeper_cli/src/utils/file_utils.dart';

class ConfigService {
  ConfigService();
  CliConfig? _config;

  Future<CliConfig> loadCliConfig() async {
    if (_config != null) {
      return _config!;
    }
    try {
      final content = await FileUtils.readFileAsString(
        FileUtils.resolvePath('~/.gatekeeper/config.json'),
      );
      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      _config = CliConfig.fromJson(jsonData);
      return _config!;
    } catch (e) {
      throw Exception('Failed to load CLI configuration: $e');
    }
  }
}
