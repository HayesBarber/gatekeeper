import 'package:gatekeeper_cli/src/models/cli_config.dart';
import 'package:gatekeeper_cli/src/utils/file_utils.dart';

/// Manages CLI configuration files.
class CliConfigService {
  CliConfigService();

  Future<void> writeConfig(CliConfig config) async {
    final json = config.toJson();
    final content = FileUtils.encodeJsonFile(json);
    await FileUtils.writeFileAsString(
      FileUtils.resolvePath('~/.gatekeeper/config.json'),
      content,
    );
  }

  Future<bool> configExists() async {
    return FileUtils.fileExists(
      FileUtils.resolvePath('~/.gatekeeper/config.json'),
    );
  }
}
