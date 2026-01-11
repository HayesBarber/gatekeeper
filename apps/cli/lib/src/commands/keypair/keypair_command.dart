import 'package:args/command_runner.dart';
import 'package:gatekeeper_cli/src/commands/keypair/export_command.dart';
import 'package:gatekeeper_cli/src/commands/keypair/generate_command.dart';
import 'package:gatekeeper_cli/src/commands/keypair/info_command.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template keypair_command}
///
/// `gk keypair`
/// Manage ECC key pairs for Gatekeeper authentication
/// {@endtemplate}
class KeypairCommand extends Command<int> {
  /// {@macro keypair_command}
  KeypairCommand({required Logger logger}) : _logger = logger {
    addSubcommand(ExportCommand(logger: _logger));
    addSubcommand(InfoCommand(logger: _logger));
    addSubcommand(GenerateCommand(logger: _logger));
  }

  @override
  String get description =>
      'Manage ECC key pairs for Gatekeeper authentication';

  @override
  String get name => 'keypair';

  final Logger _logger;

  @override
  Future<int> run() async {
    _logger
      ..info('Manage ECC key pairs for Gatekeeper authentication')
      ..info('')
      ..info('Available subcommands:')
      ..info('  export   Export public key in base64 format')
      ..info('  info     Display keypair information')
      ..info('  generate Generate new key pair')
      ..info('')
      ..info('Use "gk keypair <subcommand> --help" for more information.');
    return ExitCode.success.code;
  }
}
