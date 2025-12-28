import 'dart:io';

import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:gatekeeper/dto/challenge_verification_request.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../util/test_env.dart';

void main() {
  group('POST /challenge/verify', () {
    Future<ChallengeResponse> getChallenge() async {
      final challengeRes = await http.post(
        TestEnv.apiUri('/challenge'),
        headers: {
          'x-requestor-id': TestEnv.clientId,
        },
      );
      expect(challengeRes.statusCode, equals(HttpStatus.ok));
      expect(challengeRes.body, isNotEmpty);
      final challenge = ChallengeResponse.decode(challengeRes.body);
      expect(challenge.challengeId, isNotEmpty);
      expect(challenge.challenge, isNotEmpty);
      expect(challenge.expiresAt, isNotNull);
      return challenge;
    }

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
        body: ChallengeVerificationRequest(
          challengeId: 'invalid',
          signature: 'invalid',
        ).encode(),
      );
      expect(res.statusCode, equals(HttpStatus.notFound));
      expect(res.body, equals('No challenge found'));
    });

    test('returns 400 if challenge ID does not match provided', () async {
      final challenge = await getChallenge();
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
        headers: {
          'x-requestor-id': TestEnv.clientId,
        },
        body: ChallengeVerificationRequest(
          challengeId: '${challenge.challengeId}-invalid',
          signature: 'invalid',
        ).encode(),
      );
      expect(res.statusCode, equals(HttpStatus.badRequest));
      expect(res.body, equals('Invalid challenge'));
    });

    test('returns 400 if challenge is expired', () async {
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
        headers: {
          'x-requestor-id': TestEnv.clientId,
        },
        body: 'todo',
      );
      expect(res.statusCode, equals(HttpStatus.badRequest));
      expect(res.body, equals('Challenge expired'));
    });

    test('returns 403 for invalid signature', () async {
      final challenge = await getChallenge();
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
        headers: {
          'x-requestor-id': TestEnv.clientId,
        },
        body: ChallengeVerificationRequest(
          challengeId: challenge.challengeId,
          signature: 'invalid',
        ).encode(),
      );
      expect(res.statusCode, equals(HttpStatus.forbidden));
      expect(res.body, equals('Invalid signature'));
    });

    test('returns 200 and api key for valid handshake', () async {});
  });
}
