import 'package:args/command_runner.dart';
import 'package:gatekeeper_cli/src/commands/challenge/list_command.dart';
import 'package:gatekeeper_cli/src/services/registry.dart';
import 'package:mason_logger/mason_logger.dart';

class ChallengeCommand extends Command<int> {
  ChallengeCommand({required Logger logger, required Registry registry})
    : _logger = logger,
      _registry = registry {
    addSubcommand(ListCommand(logger: _logger, registry: _registry));
  }

  @override
  String get description => 'Manage challenges';

  @override
  String get name => 'challenge';

  final Logger _logger;
  final Registry _registry;
}
