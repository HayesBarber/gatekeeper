import 'dart:convert';

import 'package:gatekeeper_cli/src/services/key_manager.dart';
import 'package:gatekeeper_cli/src/services/registry.dart';
import 'package:gatekeeper_cli/src/services/token_manager.dart';
import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';
import 'package:mason_logger/mason_logger.dart';

class AuthService {
  AuthService(
    this._logger,
    this._keyManager,
    this._tokenManager,
  );

  final Logger _logger;
  final KeyManager _keyManager;
  final TokenManager _tokenManager;

  Future<void> getAuthToken() async {
    try {
      // Load CLI configuration to get domain and device ID
      final deviceId =
          (await Registry.I.configService.getCliConfig()).auth.deviceId;
      final apiClient = await Registry.I.apiClient;

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
}
