import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('POST /challenge', () {
    test('returns 401 if client ID header is missing', () async {
      final res = await http.post(
        Uri.parse('http://localhost:8080').resolve('/challenge'),
      );
      expect(res.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns 401 if user not found in Redis', () async {
      final res = await http.post(
        Uri.parse('http://localhost:8080').resolve('/challenge'),
        headers: {
          'x-requestor-id': '7a860417-3b7d-4777-840b-62f0a57d4353',
        },
      );
      expect(res.statusCode, equals(HttpStatus.unauthorized));
    });
  });
}
