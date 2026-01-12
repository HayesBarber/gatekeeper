import 'package:args/command_runner.dart';
import 'package:gatekeeper_cli/src/services/registry.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template export_command}
///
/// `gk keypair export`
/// Export public key in base64 format for device registration
/// {@endtemplate}
class ExportCommand extends Command<int> {
  /// {@macro export_command}
  ExportCommand({required Logger logger}) : _logger = logger;

  @override
  String get description =>
      'Export public key in base64 format for device registration';

  @override
  String get name => 'export';

  final Logger _logger;

  @override
  Future<int> run() async {
    try {
      final keyManager = Registry.I.keyManager;

      if (!await keyManager.keypairExists()) {
        _logger.err(
          'No keypair found. Run "gk init" or "gk keypair generate" first.',
        );
        return ExitCode.usage.code;
      }

      final publicKey = await keyManager.exportPublicKey();
      _logger.info(publicKey);

      return ExitCode.success.code;
    } on Exception catch (e) {
      _logger.err('Export failed: $e');
      return ExitCode.software.code;
    }
  }
}
