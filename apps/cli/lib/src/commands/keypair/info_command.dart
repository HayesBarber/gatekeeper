import 'package:args/command_runner.dart';
import 'package:gatekeeper_cli/src/services/registry.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template info_command}
///
/// `gk keypair info`
/// Display keypair information
/// {@endtemplate}
class InfoCommand extends Command<int> {
  /// {@macro info_command}
  InfoCommand({required Logger logger, required Registry registry})
    : _logger = logger,
      _registry = registry;

  @override
  String get description => 'Display keypair information';

  @override
  String get name => 'info';

  final Logger _logger;
  final Registry _registry;

  @override
  Future<int> run() async {
    try {
      final keyManager = _registry.keyManager;

      if (!await keyManager.keypairExists()) {
        _logger.err(
          'No keypair found. Run "gk init" or "gk keypair generate" first.',
        );
        return ExitCode.usage.code;
      }

      final info = await keyManager.getKeypairInfo();

      _logger
        ..info('Public Key: ${info['publicKey']}')
        ..info('Generated: ${info['generatedAt']}')
        ..info('Keypair Path: ${info['path']}');

      return ExitCode.success.code;
    } on Exception catch (e) {
      _logger.err('Failed to get keypair info: $e');
      return ExitCode.software.code;
    }
  }
}
