import 'dart:io';

import 'package:gatekeeper_cli/src/utils/file_utils.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// Manages directory operations for the CLI.
class DirectoryManager {
  DirectoryManager(this._logger);

  final Logger _logger;

  String get _gatekeeperDir => p.join(FileUtils.getHomeDir(), '.gatekeeper');

  String get _configPath => p.join(_gatekeeperDir, 'config.json');

  String get _keypairPath => p.join(_gatekeeperDir, 'keypair.json');

  Future<bool> configExists() async {
    return FileUtils.fileExists(_configPath);
  }

  Future<void> createGatekeeperDirectory() async {
    if (!await FileUtils.directoryExists(_gatekeeperDir)) {
      _logger.detail('Creating ~/.gatekeeper directory');
      await Directory(_gatekeeperDir).create(recursive: true);

      // Set directory permissions to 700 (rwx------)
      await FileUtils.setDirectoryPermissions(_gatekeeperDir, 700);
    }
  }

  Future<void> writeConfig(String content) async {
    _logger.detail('Writing configuration to $_configPath');
    await FileUtils.writeFileAsString(_configPath, content);

    // Set file permissions to 600 (rw-------)
    await FileUtils.setFilePermissions(_configPath, 600);
  }

  Future<void> writeKeypair(String content) async {
    _logger.detail('Writing keypair to $_keypairPath');
    await FileUtils.writeFileAsString(_keypairPath, content);

    // Set file permissions to 600 (rw-------)
    await FileUtils.setFilePermissions(_keypairPath, 600);
  }

  String get configPath => _configPath;

  String get keypairPath => _keypairPath;
}
