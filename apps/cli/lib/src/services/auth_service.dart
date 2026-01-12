import 'dart:convert';

import 'package:gatekeeper_cli/src/models/cli_config.dart';
import 'package:gatekeeper_cli/src/services/api_client.dart';
import 'package:gatekeeper_cli/src/services/key_manager.dart';
import 'package:gatekeeper_cli/src/services/token_manager.dart';
import 'package:gatekeeper_cli/src/services/url_builder.dart';
import 'package:gatekeeper_cli/src/utils/file_utils.dart';
import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';
import 'package:mason_logger/mason_logger.dart';

class AuthService {
  AuthService(
    this._logger,
    this._keyManager,
    this._tokenManager,
    this._isDev,
    this._urlBuilder,
  );

  final Logger _logger;
  final KeyManager _keyManager;
  final TokenManager _tokenManager;
  final bool Function() _isDev;
  final UrlBuilder _urlBuilder;

  Future<void> getAuthToken() async {
    try {
      // Load CLI configuration to get domain and device ID
      final config = await _loadCliConfig();
      final baseUrl = _urlBuilder.buildBaseUrl(
        config.gatekeeper.domain,
        useHttps: !_isDev(),
        logger: _logger,
      );
      final deviceId = config.auth.deviceId;
      final apiClient = ApiClient(baseUrl, _logger);

      // Load existing keypair
      if (!await _keyManager.keypairExists()) {
        throw Exception('No keypair found. Run "gk keypair generate" first.');
      }

      final keypairData = await _keyManager.loadKeypair();
      final privateKey = keypairData['privateKey'] as String;

      // Request challenge from API
      _logger.detail('Requesting challenge from API...');
      final challenge = await apiClient.postChallenge();

      // Sign challenge with private key
      _logger.detail('Signing challenge with private key...');
      final keyPair = ECCKeyPair.fromJson({
        'privateKey': privateKey,
        'publicKeyX': keypairData['publicKeyX'] as String,
        'publicKeyY': keypairData['publicKeyY'] as String,
      });

      final signature = await keyPair.createSignature(challenge.challenge);

      // Verify challenge to get auth token
      _logger.detail('Verifying challenge with API...');
      final authToken = await apiClient.postChallengeVerification({
        'device_id': deviceId,
        'challenge_id': challenge.challengeId,
        'signature': signature,
      });

      // Store token for CLI use
      await _tokenManager.saveAuthToken(authToken);

      // Output token in JSON format
      _logger.write(jsonEncode(authToken.toJson()));
    } catch (e) {
      _logger.err('Authentication failed: $e');
      rethrow;
    }
  }

  Future<CliConfig> _loadCliConfig() async {
    try {
      final content = await FileUtils.readFileAsString(
        FileUtils.resolvePath('~/.gatekeeper/config.json'),
      );
      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      return CliConfig.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load CLI configuration: $e');
    }
  }
}
