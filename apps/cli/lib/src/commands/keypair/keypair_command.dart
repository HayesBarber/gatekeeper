import 'package:args/command_runner.dart';
import 'package:gatekeeper_cli/src/commands/keypair/export_command.dart';
import 'package:gatekeeper_cli/src/commands/keypair/generate_command.dart';
import 'package:gatekeeper_cli/src/commands/keypair/info_command.dart';
import 'package:gatekeeper_cli/src/services/registry.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template keypair_command}
///
/// `gk keypair`
/// Manage ECC key pairs for Gatekeeper authentication
/// {@endtemplate}
class KeypairCommand extends Command<int> {
  /// {@macro keypair_command}
  KeypairCommand({required Logger logger, required Registry registry})
    : _logger = logger,
      _registry = registry {
    addSubcommand(ExportCommand(logger: _logger, registry: _registry));
    addSubcommand(InfoCommand(logger: _logger, registry: _registry));
    addSubcommand(GenerateCommand(logger: _logger, registry: _registry));
  }

  @override
  String get description =>
      'Manage ECC key pairs for Gatekeeper authentication';

  @override
  String get name => 'keypair';

  final Logger _logger;
  final Registry _registry;
}
