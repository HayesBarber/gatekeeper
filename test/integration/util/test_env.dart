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

  static final String clientIdHeader = _require('CLIENT_ID_HEADER');

  static final String keyPairJson = _require('KEY_PAIR_JSON');

  static final String redisHost = _require('REDIS_HOST');

  static Uri apiUri(String path) {
    return Uri.parse('$apiBaseUrl$path');
  }

  static Uri apiUriWithSubdomain(
    String subdomain,
    String path,
  ) {
    final uri = apiUri(path);
    final host = uri.host;
    return Uri.parse('$subdomain.$host$path');
  }

  static Map<String, String> headers = {
    TestEnv.clientIdHeader: TestEnv.clientId,
  };
}
