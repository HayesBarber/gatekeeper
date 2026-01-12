import 'dart:async';

import 'package:gatekeeper_cli/src/services/api_client.dart';
import 'package:gatekeeper_cli/src/services/auth_service.dart';
import 'package:gatekeeper_cli/src/services/config_service.dart';
import 'package:gatekeeper_cli/src/services/directory_manager.dart';
import 'package:gatekeeper_cli/src/services/key_manager.dart';
import 'package:gatekeeper_cli/src/services/token_manager.dart';
import 'package:gatekeeper_cli/src/services/url_builder.dart';
import 'package:mason_logger/mason_logger.dart';

class Registry {
  Registry(
    this._logger,
    this._isDev,
  );

  final Logger _logger;
  final bool Function() _isDev;

  ConfigService? _configService;
  ConfigService get configService {
    _configService ??= ConfigService();
    return _configService!;
  }

  UrlBuilder? _urlBuilder;
  UrlBuilder get urlBuilder {
    _urlBuilder ??= UrlBuilder();
    return _urlBuilder!;
  }

  ApiClient? _apiClient;
  FutureOr<ApiClient> get apiClient async {
    if (_apiClient != null) {
      return _apiClient!;
    }

    final domain = (await configService.getCliConfig()).gatekeeper.domain;

    final baseUrl = urlBuilder.buildBaseUrl(
      domain,
      useHttps: !_isDev(),
      logger: _logger,
    );
    _apiClient = ApiClient(baseUrl, _logger);
    return _apiClient!;
  }

  KeyManager? _keyManager;
  KeyManager get keyManager {
    _keyManager ??= KeyManager(_logger);
    return _keyManager!;
  }

  TokenManager? _tokenManager;
  TokenManager get tokenManager {
    _tokenManager ??= TokenManager();
    return _tokenManager!;
  }

  DirectoryManager? _directoryManager;
  DirectoryManager get directoryManager {
    _directoryManager ??= DirectoryManager(_logger);
    return _directoryManager!;
  }

  AuthService? _authService;
  FutureOr<AuthService> get authService async {
    _authService ??= AuthService(
      _logger,
      keyManager,
      tokenManager,
      await apiClient,
      (await configService.getCliConfig()).auth.deviceId,
    );
    return _authService!;
  }
}
