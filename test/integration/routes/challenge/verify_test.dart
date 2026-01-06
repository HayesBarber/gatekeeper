import 'dart:convert';
import 'dart:io';

import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:gatekeeper/constants/headers.dart';
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
    const challengeId = '77d17169-176c-4b36-bf94-08bcb3acd1ba';

    setUpAll(() async {
      redis = await ShorebirdRedisClient.connect(
        host: TestEnv.redisHost,
      );
    });

    tearDown(() async {
      await redis.delete(
        ns: Namespace.challenges,
        key: challengeId,
      );
    });

    tearDownAll(() async {
      await redis.close();
    });

    test('returns 401 if no public key found for client', () async {
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
        body: ChallengeVerificationRequest(
          challengeId: 'dummy',
          signature: 'sig',
          deviceId: 'dummy',
        ).encode(),
      );
      expect(res.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns 404 if challenge not found for client', () async {
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
        body: ChallengeVerificationRequest(
          challengeId: 'invalid',
          signature: 'invalid',
          deviceId: TestEnv.clientId,
        ).encode(),
      );
      expect(res.statusCode, equals(HttpStatus.notFound));
    });

    test('returns 400 if challenge is expired', () async {
      final copy = ChallengeResponse(
        challengeId: challengeId,
        challenge: 'challenge',
        expiresAt: DateTime.now().subtract(
          const Duration(seconds: 30),
        ),
      );
      await redis.set(
        ns: Namespace.challenges,
        key: challengeId,
        value: copy.encode(),
      );
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
        headers: {
          headerRequestorId: TestEnv.clientId,
        },
        body: ChallengeVerificationRequest(
          challengeId: challengeId,
          signature: 'invalid',
          deviceId: TestEnv.clientId,
        ).encode(),
      );
      expect(res.statusCode, equals(HttpStatus.badRequest));
    });

    test('returns 403 for invalid signature', () async {
      final challenge = await ItUtil.getChallenge();
      final res = await http.post(
        TestEnv.apiUri('/challenge/verify'),
        headers: {
          headerRequestorId: TestEnv.clientId,
        },
        body: ChallengeVerificationRequest(
          challengeId: challenge.challengeId,
          signature: 'invalid',
          deviceId: TestEnv.clientId,
        ).encode(),
      );
      expect(res.statusCode, equals(HttpStatus.forbidden));
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
          headerRequestorId: TestEnv.clientId,
        },
        body: ChallengeVerificationRequest(
          challengeId: challenge.challengeId,
          signature: signature,
          deviceId: TestEnv.clientId,
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
