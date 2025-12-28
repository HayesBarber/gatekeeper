import 'dart:io';

final class TestEnv {
  static String _require(String key) {
    final value = Platform.environment[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required env var: $key. '
        'Did you run tests via bin/test.sh?',
      );
    }
    return value;
  }

  static final String apiBaseUrl = _require('API_BASE_URL');

  static final String clientId = _require('CLIENT_ID');

  static Uri apiUri(String path) {
    return Uri.parse('$apiBaseUrl$path');
  }
}
