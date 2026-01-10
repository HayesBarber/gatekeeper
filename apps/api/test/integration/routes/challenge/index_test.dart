import 'dart:convert';
import 'dart:io';

import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../util/it_util.dart';
import '../../util/test_env.dart';

void main() {
  group('POST /challenge', () {
    test('returns 200 and challenge', () async {
      final res = await http.post(
        TestEnv.apiUri('/challenge'),
      );
      expect(res.statusCode, equals(HttpStatus.ok));
      expect(res.body, isNotEmpty);
      final jsonBody = jsonDecode(res.body) as Map<String, dynamic>;
      expect(jsonBody.keys, isNot(contains('session_id')));
      final challenge = ChallengeResponse(
        challengeId: jsonBody['challenge_id'] as String,
        challenge: jsonBody['challenge'] as String,
        expiresAt: DateTime.parse(jsonBody['expires_at'] as String),
        sessionId: '',
        challengeCode: jsonBody['challenge_code'] as String,
      );
      expect(challenge.challengeId, isNotEmpty);
      expect(challenge.challenge, isNotEmpty);
      expect(challenge.expiresAt, isNotNull);
    });
  });

  group('non-POST methods', () {
    final methods = [
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

  group('GET /challenge', () {
    late RedisClientBase redis;

    setUpAll(() async {
      redis = await ShorebirdRedisClient.connect(host: TestEnv.redisHost);
    });

    tearDown(() async {
      await redis.deleteAll(
        ns: Namespace.challenges,
      );
      await redis.deleteAll(
        ns: Namespace.apiKeys,
      );
    });

    tearDownAll(() async {
      await redis.close();
    });

    test('returns 401 if API key is missing', () async {
      final res = await http.get(
        TestEnv.apiUri('/challenge'),
      );
      expect(res.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns 403 with invalid API key', () async {
      final res = await http.get(
        TestEnv.apiUri('/challenge'),
        headers: {
          headerAuthorization: 'Bearer invalid-key',
        },
      );
      expect(res.statusCode, equals(HttpStatus.forbidden));
    });

    test('returns empty array when no challenges exist', () async {
      final challenge = await ItUtil.getChallenge();
      final apiKeyResponse = await ItUtil.verifyChallengeAndGetApiKey(
        challenge.challengeId,
        challenge.challenge,
      );

      final res = await http.get(
        TestEnv.apiUri('/challenge'),
        headers: {
          headerAuthorization: 'Bearer ${apiKeyResponse.apiKey}',
        },
      );

      expect(res.statusCode, equals(HttpStatus.ok));
      final challenges = jsonDecode(res.body) as List;
      expect(challenges, isEmpty);
    });

    test('returns only non-verified challenges', () async {
      final challenge1 = await ItUtil.getChallenge();

      final challenge2 = await ItUtil.getChallenge();
      final apiKeyResponse = await ItUtil.verifyChallengeAndGetApiKey(
        challenge2.challengeId,
        challenge2.challenge,
      );

      final res = await http.get(
        TestEnv.apiUri('/challenge'),
        headers: {
          headerAuthorization: 'Bearer ${apiKeyResponse.apiKey}',
        },
      );

      expect(res.statusCode, equals(HttpStatus.ok));
      final challenges =
          (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      expect(challenges.length, equals(1));
      expect(challenges[0]['challenge_id'], equals(challenge1.challengeId));
      expect(challenges[0]['challenge'], equals(challenge1.challenge));
      expect(challenges[0]['challenge_code'], equals(challenge1.challengeCode));
      expect(challenges[0].keys, isNot(contains('session_id')));
    });

    test('returns challenges with correct fields only', () async {
      final challenge = await ItUtil.getChallenge();
      final apiKeyResponse = await ItUtil.verifyChallengeAndGetApiKey(
        challenge.challengeId,
        challenge.challenge,
      );

      final challenge2 = await ItUtil.getChallenge();

      final res = await http.get(
        TestEnv.apiUri('/challenge'),
        headers: {
          headerAuthorization: 'Bearer ${apiKeyResponse.apiKey}',
        },
      );

      expect(res.statusCode, equals(HttpStatus.ok));
      final challenges =
          (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      expect(challenges.length, equals(1));

      final challengeData = challenges[0];
      expect(challengeData.keys.length, equals(4));
      expect(
        challengeData.keys,
        containsAll(
          ['challenge_id', 'challenge', 'expires_at', 'challenge_code'],
        ),
      );
      expect(challengeData.keys, isNot(contains('session_id')));
      expect(challengeData['challenge_id'], equals(challenge2.challengeId));
      expect(challengeData['challenge'], equals(challenge2.challenge));
      expect(challengeData['challenge_code'], equals(challenge2.challengeCode));
      expect(challengeData['expires_at'], isA<String>());
    });

    test('filters out expired challenges', () async {
      final challenge = await ItUtil.getChallenge();
      final apiKeyResponse = await ItUtil.verifyChallengeAndGetApiKey(
        challenge.challengeId,
        challenge.challenge,
      );

      final expiredChallenge = ChallengeResponse(
        challengeId: CryptoUtils.generateId(),
        challenge: CryptoUtils.generateBytes(),
        expiresAt: DateTime.now().subtract(const Duration(seconds: 45)),
        sessionId: 'test-session-id',
      );

      await redis.set(
        ns: Namespace.challenges,
        key: expiredChallenge.challengeId,
        value: expiredChallenge.encode(),
      );

      final res = await http.get(
        TestEnv.apiUri('/challenge'),
        headers: {
          headerAuthorization: 'Bearer ${apiKeyResponse.apiKey}',
        },
      );

      expect(res.statusCode, equals(HttpStatus.ok));
      final challenges =
          (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      expect(challenges.length, equals(0));
    });
  });
}
