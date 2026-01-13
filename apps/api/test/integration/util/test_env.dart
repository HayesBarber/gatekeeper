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

  static final Uri _baseUri = Uri.parse(_require('API_BASE_URL'));

  static final String deviceId = _require('DEVICE_ID');
  static final String keyPairJson = _require('KEY_PAIR_JSON');
  static final String redisHost = _require('REDIS_HOST');
  static final String githubWebhookSecret = _require('GITHUB_WEBHOOK_SECRET');

  static Uri apiUri(String path) {
    return _baseUri.replace(path: path);
  }

  static Map<String, String> headersWithSubdomain(String subdomain) {
    final extension = _baseUri.host == 'localhost' ? '.com' : '';
    final host = _baseUri.hasPort
        ? '$subdomain.${_baseUri.host}$extension:${_baseUri.port}'
        : '$subdomain.${_baseUri.host}$extension';

    return {
      'host': host,
    };
  }
}
