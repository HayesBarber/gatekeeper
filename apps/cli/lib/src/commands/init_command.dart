import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:gatekeeper_cli/src/services/config_mapper.dart';
import 'package:gatekeeper_cli/src/services/directory_manager.dart';
import 'package:gatekeeper_cli/src/services/key_manager.dart';
import 'package:gatekeeper_cli/src/utils/file_utils.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template init_command}
///
/// `gk init`
/// Initialize CLI configuration from a Gatekeeper configuration file
/// {@endtemplate}
class InitCommand extends Command<int> {
  /// {@macro init_command}
  InitCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'from',
        mandatory: true,
        help: 'Path to the gatekeeper configuration JSON file',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Overwrite existing configuration and key pair',
        negatable: false,
      );
  }

  @override
  String get description =>
      'Initialize CLI configuration and generate a key pair';

  @override
  String get name => 'init';

  final Logger _logger;

  @override
  Future<int> run() async {
    try {
      final fromPath = argResults!['from'] as String;
      final force = argResults!['force'] as bool;

      // Validate input file exists and is readable
      _validateInputFile(fromPath);

      // Initialize services
      final directoryManager = DirectoryManager(_logger);
      final keyManager = KeyManager(_logger);

      // Check for existing configuration
      if (await directoryManager.configExists() && !force) {
        _logger.err('Configuration already exists. Use --force to overwrite.');
        return ExitCode.usage.code;
      }

      // Load and validate Gatekeeper configuration
      _logger.detail('Loading and validating Gatekeeper configuration...');
      final appConfig = await _loadGatekeeperConfig(fromPath);

      // Create CLI directory structure
      await directoryManager.createGatekeeperDirectory();

      // Generate key pair
      _logger.detail('Generating ECC key pair...');
      final keypairJson = await keyManager.generateKeypair();

      // Map to CLI configuration
      final generatedAt = DateTime.now().toIso8601String();
      final cliConfig = ConfigMapper.mapToCliConfig(
        appConfig,
        fromPath,
        generatedAt,
      );

      // Write files
      await directoryManager.writeKeypair(keypairJson);
      await directoryManager.writeConfig(
        FileUtils.encodeJsonFile(cliConfig.toJson()),
      );

      // Show success
      _showSuccess(directoryManager, appConfig.subdomains.keys.toList());

      return ExitCode.success.code;
    } on Exception catch (e) {
      _logger.err('Initialization failed: $e');
      return ExitCode.software.code;
    }
  }

  void _validateInputFile(String path) {
    if (!File(path).existsSync()) {
      throw FileSystemException('Configuration file not found', path);
    }
  }

  Future<AppConfig> _loadGatekeeperConfig(String path) async {
    final configService = JsonConfigService(path);
    await configService.reload();
    return configService.config;
  }

  void _showSuccess(
    DirectoryManager directoryManager,
    List<String> subdomains,
  ) {
    _logger
      ..success(
        'Gatekeeper configuration loaded and validated successfully',
      )
      ..success('ECC key pair generated and stored')
      ..success(
        'CLI configuration created at ${directoryManager.configPath}',
      )
      ..success('Discovered subdomains: ${subdomains.join(', ')}');
  }
}
