import 'dart:io';

import 'package:gatekeeper/constants/headers.dart';

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

  static final String clientId = _require('CLIENT_ID');
  static final String keyPairJson = _require('KEY_PAIR_JSON');
  static final String redisHost = _require('REDIS_HOST');

  static Uri apiUri(String path) {
    return _baseUri.replace(path: path);
  }

  static Map<String, String> headersWithSubdomain(
    String subdomain, {
    bool includeClientId = true,
  }) {
    final host = _baseUri.hasPort
        ? '$subdomain.${_baseUri.host}:${_baseUri.port}'
        : '$subdomain.${_baseUri.host}';

    return {
      if (includeClientId) headerRequestorId: clientId,
      'host': host,
    };
  }
}
