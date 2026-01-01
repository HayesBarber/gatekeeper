import 'dart:io';

import 'package:gatekeeper/constants/headers.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../util/test_env.dart';

void main() {
  group('GitHub webhook middleware', () {
    test('returns 200 healthy when no subdomain matches', () async {
      final res = await http.get(
        TestEnv.apiUri('/health'),
      );
      expect(res.statusCode, equals(HttpStatus.ok));
      expect(res.body, equals('healthy'));
    });

    test('returns 401 for missing signature header', () async {
      final res = await http.get(
        TestEnv.apiUri('/echo'),
        headers: TestEnv.headersWithSubdomain(
          'github',
        ),
      );
      expect(res.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns 401 for invalid signature', () async {
      final res = await http.get(
        TestEnv.apiUri('/echo'),
        headers: {
          ...TestEnv.headersWithSubdomain(
            'github',
          ),
          hubSignature: 'invalid',
        },
      );
      expect(res.statusCode, equals(HttpStatus.unauthorized));
    });

    test(
      'returns 200 from upstream for valid GitHub webhook signature',
      () async {},
    );

    test('handles empty body with valid signature', () async {});

    test('handles large payload with valid signature', () async {});
  });
}
