import 'dart:convert';
import 'dart:io';

import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:gatekeeper/dto/challenge_verification_request.dart';
import 'package:gatekeeper/dto/challenge_verification_response.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../util/it_util.dart';
import '../../util/test_env.dart';

void main() {
  group('POST /challenge/verify', () {
    late RedisClientBase redis;

    setUpAll(() async {
      redis = await ShorebirdRedisClient.connect(
        host: TestEnv.redisHost,
      );
    });

    tearDown(() async {
      await redis.delete(
        ns: Namespace.challenges,
        key: TestEnv.clientId,
      );
    });

    tearDownAll(() async {
      await redis.close();
    });

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
          TestEnv.clientIdHeader: 'eb893043-d510-460b-ace7-c9b9057d16d9',
        },
      );
      expect(res.statusCode, equals(HttpStatus.unauthorized));
      expect(res.body, equals('Unauthorized'));
    });

    test('returns 404 if challenge not found for client', () async {
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
        headers: {
          TestEnv.clientIdHeader: TestEnv.clientId,
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
      final challenge = await ItUtil.getChallenge();
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
        headers: {
          TestEnv.clientIdHeader: TestEnv.clientId,
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
      final challenge = await ItUtil.getChallenge();
      final copy = ChallengeResponse(
        challengeId: challenge.challengeId,
        challenge: challenge.challenge,
        expiresAt: DateTime.now().subtract(
          const Duration(seconds: 30),
        ),
      );
      await redis.set(
        ns: Namespace.challenges,
        key: TestEnv.clientId,
        value: copy.encode(),
      );
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
        headers: {
          TestEnv.clientIdHeader: TestEnv.clientId,
        },
        body: ChallengeVerificationRequest(
          challengeId: challenge.challengeId,
          signature: 'invalid',
        ).encode(),
      );
      expect(res.statusCode, equals(HttpStatus.badRequest));
      expect(res.body, equals('Challenge expired'));
    });

    test('returns 403 for invalid signature', () async {
      final challenge = await ItUtil.getChallenge();
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
        headers: {
          TestEnv.clientIdHeader: TestEnv.clientId,
        },
        body: ChallengeVerificationRequest(
          challengeId: challenge.challengeId,
          signature: 'invalid',
        ).encode(),
      );
      expect(res.statusCode, equals(HttpStatus.forbidden));
      expect(res.body, equals('Invalid signature'));
    });

    test('returns 200 and api key for valid handshake', () async {
      final challenge = await ItUtil.getChallenge();
      final keyPair = ECCKeyPair.fromJson(
        Map<String, String>.from(
          jsonDecode(TestEnv.keyPairJson) as Map<String, dynamic>,
        ),
      );
      final signature = await keyPair.createSignature(challenge.challenge);
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
        headers: {
          TestEnv.clientIdHeader: TestEnv.clientId,
        },
        body: ChallengeVerificationRequest(
          challengeId: challenge.challengeId,
          signature: signature,
        ).encode(),
      );
      expect(res.statusCode, equals(HttpStatus.ok));
      expect(res.body, isNotEmpty);
      final apiKeyResponse = ChallengeVerificationResponse.decode(res.body);
      expect(apiKeyResponse.apiKey, isNotEmpty);
      expect(apiKeyResponse.expiresAt, isNotNull);
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
          TestEnv.apiUri('/challenge/verify'),
        );
        expect(res.statusCode, equals(HttpStatus.methodNotAllowed));
      });
    }
  });
}
