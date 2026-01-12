import 'dart:async';

import 'package:gatekeeper_cli/src/services/api_client.dart';
import 'package:gatekeeper_cli/src/services/config_service.dart';
import 'package:gatekeeper_cli/src/services/url_builder.dart';
import 'package:mason_logger/mason_logger.dart';

class Registery {
  Registery._(
    this._logger,
    this._isDev,
  );
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
  final bool Function() _isDev;

  ConfigService? _configService;
  ConfigService get configService {
    _configService ??= ConfigService();
    return _configService!;
  }

  ApiClient? _apiClient;
  FutureOr<ApiClient> get apiClient async {
    if (_apiClient != null) {
      return _apiClient!;
    }

    final domain = (await configService.getCliConfig()).gatekeeper.domain;

    final baseUrl = UrlBuilder().buildBaseUrl(
      domain,
      useHttps: !_isDev(),
      logger: _logger,
    );
    _apiClient = ApiClient(baseUrl, _logger);
    return _apiClient!;
  }
}
