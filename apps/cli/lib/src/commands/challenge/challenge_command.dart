import 'package:args/command_runner.dart';
import 'package:gatekeeper_cli/src/commands/challenge/list_command.dart';
import 'package:mason_logger/mason_logger.dart';

class ChallengeCommand extends Command<int> {
  ChallengeCommand({required Logger logger, required bool Function() isDev}) {
    addSubcommand(ListCommand(logger: logger, isDev: isDev));
  }

  @override
  String get description => 'Manage challenges';

  @override
  String get name => 'challenge';
}
