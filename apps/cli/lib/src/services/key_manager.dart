import 'dart:convert';
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

    // Add public key in base64 format for convenience
    keyData['publicKey'] = keyPair.exportPublicKeyRawBase64();
    keyData['generatedAt'] = DateTime.now().toIso8601String();

    final jsonContent = FileUtils.encodeJsonFile(keyData);
    return jsonContent;
  }

  Future<void> saveKeypair(String jsonContent) async {
    await FileUtils.writeFileAsString(
      FileUtils.resolvePath('~/.gatekeeper/keypair.json'),
      jsonContent,
    );
  }

  Future<bool> keypairExists() async {
    return FileUtils.fileExists(
      FileUtils.resolvePath('~/.gatekeeper/keypair.json'),
    );
  }

  Future<String> exportPublicKey() async {
    final keypairData = await loadKeypair();
    return keypairData['publicKey'] as String;
  }

  Future<Map<String, dynamic>> getKeypairInfo() async {
    final keypairData = await loadKeypair();
    return {
      'publicKey': keypairData['publicKey'],
      'path': FileUtils.resolvePath('~/.gatekeeper/keypair.json'),
      'generatedAt': keypairData['generatedAt'] ?? 'Unknown',
    };
  }

  Future<Map<String, dynamic>> loadKeypair() async {
    final content = await FileUtils.readFileAsString(
      FileUtils.resolvePath('~/.gatekeeper/keypair.json'),
    );
    final keypairData = parseKeypairJson(content);
    return keypairData;
  }

  static Map<String, dynamic> parseKeypairJson(String jsonContent) {
    try {
      final decoded = jsonDecode(jsonContent) as Map<String, dynamic>;
      return decoded;
    } catch (e) {
      throw FormatException('Invalid keypair format: $e');
    }
  }
}
