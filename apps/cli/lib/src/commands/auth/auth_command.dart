import 'package:args/command_runner.dart';
import 'package:gatekeeper_cli/src/commands/auth/token_command.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template auth_command}
///
/// `gk auth`
/// Manage authentication with Gatekeeper API
/// {@endtemplate}
class AuthCommand extends Command<int> {
  /// {@macro auth_command}
  AuthCommand({required Logger logger}) {
    addSubcommand(TokenCommand(logger: logger));
  }

  @override
  String get description => 'Manage authentication with Gatekeeper API';

  @override
  String get name => 'auth';
}
