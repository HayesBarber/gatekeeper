import 'package:args/command_runner.dart';
import 'package:gatekeeper_cli/src/services/key_manager.dart';
import 'package:gatekeeper_cli/src/services/registry.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template generate_command}
///
/// `gk keypair generate`
/// Generate new ECC key pair
/// {@endtemplate}
class GenerateCommand extends Command<int> {
  /// {@macro generate_command}
  GenerateCommand({required Logger logger, required Registry registry})
    : _logger = logger,
      _registry = registry {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Skip confirmation when overwriting existing keypair',
      negatable: false,
    );
  }

  @override
  String get description => 'Generate new ECC key pair';

  @override
  String get name => 'generate';

  final Logger _logger;
  final Registry _registry;

  @override
  Future<int> run() async {
    try {
      final force = argResults!['force'] as bool;
      final keyManager = _registry.keyManager;

      // Check if keypair exists and get confirmation if needed
      if (await keyManager.keypairExists() && !force) {
        final info = await keyManager.getKeypairInfo();
        _logger
          ..warn(' Keypair already exists at ${info['path']}')
          ..info('Public Key: ${info['publicKey']}')
          ..info('Generated: ${info['generatedAt']}')
          ..info('');

        final confirmed = await _confirmOverwrite();
        if (!confirmed) {
          _logger.info('Keypair generation cancelled.');
          return ExitCode.success.code;
        }
      }

      // Generate new keypair
      final keypairJson = await keyManager.generateNewKeypair();
      await keyManager.saveKeypair(keypairJson);

      // Extract public key for display
      final keypairData = KeyManager.parseKeypairJson(keypairJson);
      final publicKey = keypairData['publicKey'] as String;

      _logger
        ..success(
          'New ECC key pair generated and stored at ~/.gatekeeper/keypair.json',
        )
        ..info('Public Key: $publicKey');

      return ExitCode.success.code;
    } on Exception catch (e) {
      _logger.err('Keypair generation failed: $e');
      return ExitCode.software.code;
    }
  }

  Future<bool> _confirmOverwrite() async {
    final response = _logger.confirm(
      'Are you sure you want to overwrite this keypair? [y/N]: ',
    );
    return response;
  }
}
