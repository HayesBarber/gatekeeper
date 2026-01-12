import 'package:gatekeeper_cli/src/services/config_service.dart';
import 'package:mason_logger/mason_logger.dart';

class Registery {
  Registery._(this._logger);
  static Registery? _instance;

  static Registery get I {
    if (_instance == null) {
      throw StateError(
        'Registery not initialized',
      );
    }
    return _instance!;
  }

  final Logger _logger;

  ConfigService? _configService;
  ConfigService get configService {
    _configService ??= ConfigService();
    return _configService!;
  }
}
