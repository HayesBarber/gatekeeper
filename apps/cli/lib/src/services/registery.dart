import 'package:gatekeeper_cli/src/services/config_service.dart';

class Registery {
  Registery._();
  static final _instance = Registery._();

  static Registery get I => _instance;

  ConfigService? _configService;
  ConfigService get configService {
    _configService ??= ConfigService();
    return _configService!;
  }
}
