import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:gatekeeper_cli/src/commands/commands.dart';
import 'package:gatekeeper_cli/src/version.dart';
import 'package:mason_logger/mason_logger.dart';

const executableName = 'gk';
const packageName = 'gatekeeper_cli';
const description = 'gatekeeper cli';

class GatekeeperCliCommandRunner extends CompletionCommandRunner<int> {
  GatekeeperCliCommandRunner({
    Logger? logger,
  }) : _logger = logger ?? Logger(),
       super(executableName, description) {
    argParser
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Print the current version.',
      )
      ..addFlag(
        'verbose',
        help: 'Noisy logging, including all shell commands executed.',
      );

    addCommand(InitCommand(logger: _logger));
    addCommand(KeypairCommand(logger: _logger));
    addCommand(AuthCommand(logger: _logger));
    addCommand(ChallengeCommand(logger: _logger));
  }

  @override
  void printUsage() => _logger.info(usage);

  final Logger _logger;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);
      if (topLevelResults['verbose'] == true) {
        _logger.level = Level.verbose;
      }
      return await runCommand(topLevelResults) ?? ExitCode.success.code;
    } on FormatException catch (e, stackTrace) {
      _logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.command?.name == 'completion') {
      await super.runCommand(topLevelResults);
      return ExitCode.success.code;
    }

    _logger
      ..detail('Argument information:')
      ..detail('  Top level options:');
    for (final option in topLevelResults.options) {
      if (topLevelResults.wasParsed(option)) {
        _logger.detail('  - $option: ${topLevelResults[option]}');
      }
    }
    if (topLevelResults.command != null) {
      final commandResult = topLevelResults.command!;
      _logger
        ..detail('  Command: ${commandResult.name}')
        ..detail('    Command options:');
      for (final option in commandResult.options) {
        if (commandResult.wasParsed(option)) {
          _logger.detail('    - $option: ${commandResult[option]}');
        }
      }
    }

    final int? exitCode;
    if (topLevelResults['version'] == true) {
      _logger.info(packageVersion);
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }

    return exitCode;
  }
}
