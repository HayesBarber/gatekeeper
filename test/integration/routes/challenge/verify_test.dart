import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../util/test_env.dart';

void main() {
  group('POST /challenge/verify', () {
    test('returns 401 if client ID header is missing', () async {
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
      );
      expect(res.statusCode, equals(HttpStatus.unauthorized));
      expect(res.body, equals('Unauthorized'));
    });

    test('returns 401 if no public key found for client', () async {
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
        headers: {
          'x-requestor-id': 'eb893043-d510-460b-ace7-c9b9057d16d9',
        },
      );
      expect(res.statusCode, equals(HttpStatus.unauthorized));
      expect(res.body, equals('Unauthorized'));
    });

    test('returns 404 if challenge not found for client', () async {
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
        headers: {
          'x-requestor-id': TestEnv.clientId,
        },
      );
      expect(res.statusCode, equals(HttpStatus.notFound));
      expect(res.body, equals('No challenge found'));
    });

    test('returns 400 if challenge ID does not match provided', () async {});

    test('returns 400 if challenge is expired', () async {});

    test('returns 403 for invalid signature', () async {});

    test('returns 200 and api key for valid handshake', () async {});
  });
}
