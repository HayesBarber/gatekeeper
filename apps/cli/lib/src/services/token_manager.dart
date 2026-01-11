import 'dart:convert';

import 'package:gatekeeper_cli/src/models/auth_token_response.dart';
import 'package:gatekeeper_cli/src/utils/file_utils.dart';

class TokenManager {
  TokenManager();

  Future<void> saveAuthToken(AuthTokenResponse token) async {
    final tokenData = AuthTokenResponse(
      apiKey: token.apiKey,
      expiresAt: token.expiresAt,
    );

    final jsonContent = FileUtils.encodeJsonFile(tokenData.toJson());
    await FileUtils.writeFileAsString(
      FileUtils.resolvePath('~/.gatekeeper/auth_token.json'),
      jsonContent,
    );
  }

  Future<AuthTokenResponse?> getStoredToken() async {
    try {
      final content = await FileUtils.readFileAsString(
        FileUtils.resolvePath('~/.gatekeeper/auth_token.json'),
      );
      final tokenData = jsonDecode(content) as Map<String, dynamic>;
      return AuthTokenResponse.fromJson(tokenData);
    } on Exception catch (_) {
      return null;
    }
  }
}
