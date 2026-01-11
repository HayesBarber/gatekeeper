import 'package:gatekeeper_cli/src/utils/file_utils.dart';
import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';
import 'package:mason_logger/mason_logger.dart';

/// Manages ECC key pair generation and storage.
class KeyManager {
  KeyManager(this._logger);

  final Logger _logger;

  Future<String> generateKeypair() async {
    _logger.detail('Generating new ECC key pair');

    final keyPair = ECCKeyPair.generate();
    final keyData = keyPair.toJson();

    // Add the public key in base64 format for convenience
    keyData['publicKey'] = keyPair.exportPublicKeyRawBase64();

    final jsonContent = FileUtils.encodeJsonFile(keyData);
    return jsonContent;
  }

  Future<void> saveKeypair(String jsonContent) async {
    await FileUtils.writeFileAsString(
      FileUtils.resolvePath('~/.gatekeeper/keypair.json'),
      jsonContent,
    );
  }
}
