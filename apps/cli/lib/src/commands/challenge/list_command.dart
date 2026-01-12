import 'package:args/command_runner.dart';
import 'package:gatekeeper_cli/src/models/auth_token_response.dart';
import 'package:gatekeeper_cli/src/models/challenge_info.dart';
import 'package:gatekeeper_cli/src/services/api_client.dart';
import 'package:gatekeeper_cli/src/services/registry.dart';
import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';
import 'package:mason_logger/mason_logger.dart';

class ListCommand extends Command<int> {
  ListCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get description => 'List and verify challenges';

  @override
  String get name => 'list';

  @override
  Future<int> run() async {
    try {
      // Check and refresh auth token if needed
      final authToken = await _ensureValidAuthToken();

      final apiClient = await Registry.I.apiClient;

      // Get challenges list
      final challenges = await apiClient.getChallenges(authToken.authToken);

      if (challenges.isEmpty) {
        _logger.info('No challenges available');
        return ExitCode.success.code;
      }

      // Display numbered list with challenge IDs and expirations
      for (var i = 0; i < challenges.length; i++) {
        final challenge = challenges[i];
        final timeUntilExpiry = challenge.expiresAt.difference(DateTime.now());
        final minutes = timeUntilExpiry.inMinutes;
        final seconds = timeUntilExpiry.inSeconds % 60;

        _logger.info(
          '${i + 1}. ${challenge.challengeId} '
          '(expires in ${minutes}m ${seconds}s)',
        );
      }

      // Interactive challenge selection and verification
      await _selectAndVerifyChallenge(apiClient, challenges);

      return ExitCode.success.code;
    } on Exception catch (e) {
      _logger.err('Command failed: $e');
      return ExitCode.software.code;
    }
  }

  Future<AuthTokenResponse> _ensureValidAuthToken() async {
    _logger.detail('Checking stored auth token...');

    final storedToken = await Registry.I.tokenManager.getStoredToken();

    // Check if token exists and is not expired
    if (storedToken != null && storedToken.expiresAt.isAfter(DateTime.now())) {
      _logger.detail('Auth token is valid');
      return storedToken;
    }

    _logger.detail(
      'Auth token missing or expired, refreshing automatically...',
    );

    // Refresh auth token using the same flow as auth command
    final authService = Registry.I.authService;
    await authService.getAuthToken();

    final newToken = await Registry.I.tokenManager.getStoredToken();
    if (newToken == null) {
      throw Exception('Failed to refresh auth token');
    }

    _logger.detail('Auth token refreshed successfully');
    return newToken;
  }

  Future<void> _selectAndVerifyChallenge(
    ApiClient apiClient,
    List<ChallengeInfo> challenges,
  ) async {
    // Load device ID from CLI config
    final config = await Registry.I.configService.getCliConfig();
    final deviceId = config.auth.deviceId;

    var attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        // Prompt for challenge selection
        final selection = _logger.prompt('Select challenge by number:');
        final selectedIndex = int.parse(selection) - 1;

        if (selectedIndex < 0 || selectedIndex >= challenges.length) {
          attempts++;
          _logger.err(
            'Invalid selection. Please enter a number '
            'between 1 and ${challenges.length}',
          );
          continue;
        }

        final selectedChallenge = challenges[selectedIndex];

        // Prompt for challenge code
        final userCode = _logger.prompt('Enter challenge code:');

        // Validate challenge code
        if (userCode != selectedChallenge.challengeCode) {
          _logger.err('Invalid challenge code');
          return;
        }

        // Load keypair for signing
        final keypairData = await Registry.I.keyManager.loadKeypair();
        final privateKey = keypairData['privateKey'] as String;

        final keyPair = ECCKeyPair.fromJson({
          'privateKey': privateKey,
          'publicKeyX': keypairData['publicKeyX'] as String,
          'publicKeyY': keypairData['publicKeyY'] as String,
        });

        // Sign the challenge
        _logger.detail('Signing challenge with private key...');
        final signature = await keyPair.createSignature(
          selectedChallenge.challenge,
        );

        // Verify challenge
        await apiClient.postChallengeVerification({
          'device_id': deviceId,
          'challenge_id': selectedChallenge.challengeId,
          'signature': signature,
        });

        _logger.info('Challenge verified successfully!');
        return;
      } on FormatException {
        attempts++;
        _logger.err('Invalid input. Please enter a valid number.');
      } on Exception catch (e) {
        _logger.err('Verification failed: $e');
        return;
      }
    }

    _logger.err('Too many invalid attempts. Exiting.');
    return;
  }
}
