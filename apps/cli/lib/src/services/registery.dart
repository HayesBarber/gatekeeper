import 'package:gatekeeper_cli/src/services/config_service.dart';

class Registery {
  ConfigService? _configService;
  ConfigService get configService {
    _configService ??= ConfigService();
    return _configService!;
  }
}
