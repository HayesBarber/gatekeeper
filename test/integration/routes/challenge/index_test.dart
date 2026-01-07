import 'dart:io';

import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../util/test_env.dart';

void main() {
  group('POST /challenge', () {
    test('returns 200 and challenge', () async {
      final res = await http.post(
        TestEnv.apiUri('/challenge'),
      );
      expect(res.statusCode, equals(HttpStatus.ok));
      expect(res.body, isNotEmpty);
      final challenge = ChallengeResponse.decode(res.body);
      expect(challenge.challengeId, isNotEmpty);
      expect(challenge.challenge, isNotEmpty);
      expect(challenge.expiresAt, isNotNull);
    });
  });

  group('non-POST methods', () {
    final methods = [
      (http.get, 'GET'),
      (http.put, 'PUT'),
      (http.patch, 'PATCH'),
      (http.delete, 'DELETE'),
    ];

    for (final record in methods) {
      test('${record.$2} returns 405', () async {
        final res = await record.$1(
          TestEnv.apiUri('/challenge'),
        );
        expect(res.statusCode, equals(HttpStatus.methodNotAllowed));
      });
    }
  });
}
