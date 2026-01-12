import 'package:args/command_runner.dart';
import 'package:gatekeeper_cli/src/services/registry.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template token_command}
///
/// `gk auth token`
/// Get authentication token from API
/// {@endtemplate}
class TokenCommand extends Command<int> {
  /// {@macro token_command}
  TokenCommand({
    required Logger logger,
    required Registry registry,
  }) : _logger = logger,
       _registry = registry;

  @override
  String get description => 'Get authentication token from API';

  @override
  String get name => 'token';

  final Logger _logger;
  final Registry _registry;

  @override
  Future<int> run() async {
    try {
      await (await _registry.authService).getAuthToken();

      return ExitCode.success.code;
    } on Exception catch (e) {
      _logger.err('Authentication failed: $e');
      return ExitCode.software.code;
    }
  }
}
