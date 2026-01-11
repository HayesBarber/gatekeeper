import 'dart:convert';
import 'dart:io';

import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart';
import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../../util/test_env.dart';

void main() {
  group('GET /challenge/poll/[id]', () {
    late RedisClientBase redis;

    setUpAll(() async {
      redis = await ShorebirdRedisClient.connect(host: TestEnv.redisHost);
    });

    tearDown(() async {
      await redis.deleteAll(
        ns: Namespace.challenges,
      );
      await redis.deleteAll(
        ns: Namespace.authTokens,
      );
    });

    tearDownAll(() async {
      await redis.close();
    });

    test('returns 405 for non-GET methods', () async {
      final methods = [
        (http.post, 'POST'),
        (http.put, 'PUT'),
        (http.patch, 'PATCH'),
        (http.delete, 'DELETE'),
      ];

      for (final record in methods) {
        final res = await record.$1(
          TestEnv.apiUri('/challenge/poll/invalid-id'),
        );
        expect(res.statusCode, equals(HttpStatus.methodNotAllowed));
      }
    });

    test('returns 401 when session_id cookie is missing', () async {
      final res = await http.get(
        TestEnv.apiUri('/challenge/poll/invalid-id'),
      );
      expect(res.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns 404 when challenge does not exist', () async {
      final sessionId = CryptoUtils.generateId();
      final res = await http.get(
        TestEnv.apiUri('/challenge/poll/nonexistent-id'),
        headers: {'cookie': 'session_id=$sessionId'},
      );
      expect(res.statusCode, equals(HttpStatus.notFound));
    });

    test('returns 400 when challenge is expired', () async {
      final sessionId = CryptoUtils.generateId();
      final expiredChallenge = ChallengeResponse(
        challengeId: CryptoUtils.generateId(),
        challenge: CryptoUtils.generateBytes(),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        sessionId: sessionId,
      );

      await redis.set(
        ns: Namespace.challenges,
        key: expiredChallenge.challengeId,
        value: expiredChallenge.encode(),
      );

      final res = await http.get(
        TestEnv.apiUri('/challenge/poll/${expiredChallenge.challengeId}'),
        headers: {'cookie': 'session_id=$sessionId'},
      );
      expect(res.statusCode, equals(HttpStatus.badRequest));
    });

    test('returns 403 when session ID does not match', () async {
      final correctSessionId = CryptoUtils.generateId();
      final wrongSessionId = CryptoUtils.generateId();
      final challenge = ChallengeResponse(
        challengeId: CryptoUtils.generateId(),
        challenge: CryptoUtils.generateBytes(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        sessionId: correctSessionId,
      );

      await redis.set(
        ns: Namespace.challenges,
        key: challenge.challengeId,
        value: challenge.encode(),
      );

      final res = await http.get(
        TestEnv.apiUri('/challenge/poll/${challenge.challengeId}'),
        headers: {'cookie': 'session_id=$wrongSessionId'},
      );
      expect(res.statusCode, equals(HttpStatus.forbidden));
    });

    test('returns pending status when challenge is not verified', () async {
      final sessionId = CryptoUtils.generateId();
      final unverifiedChallenge = ChallengeResponse(
        challengeId: CryptoUtils.generateId(),
        challenge: CryptoUtils.generateBytes(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        sessionId: sessionId,
      );

      await redis.set(
        ns: Namespace.challenges,
        key: unverifiedChallenge.challengeId,
        value: unverifiedChallenge.encode(),
      );

      final res = await http.get(
        TestEnv.apiUri('/challenge/poll/${unverifiedChallenge.challengeId}'),
        headers: {'cookie': 'session_id=$sessionId'},
      );
      expect(res.statusCode, equals(HttpStatus.ok));

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      expect(body['status'], equals('pending'));
    });

    test('returns 410 when challenge has already been polled', () async {
      final sessionId = CryptoUtils.generateId();
      final authToken = CryptoUtils.generateId();
      final polledChallenge = ChallengeResponse(
        challengeId: CryptoUtils.generateId(),
        challenge: CryptoUtils.generateBytes(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        sessionId: sessionId,
        isVerified: true,
        verifiedAt: DateTime.now(),
        isPolled: true,
        authToken: authToken,
      );

      await redis.set(
        ns: Namespace.challenges,
        key: polledChallenge.challengeId,
        value: polledChallenge.encode(),
      );

      final res = await http.get(
        TestEnv.apiUri('/challenge/poll/${polledChallenge.challengeId}'),
        headers: {'cookie': 'session_id=$sessionId'},
      );
      expect(res.statusCode, equals(HttpStatus.gone));
    });

    test('returns approved status and sets API key cookie on success',
        () async {
      final sessionId = CryptoUtils.generateId();
      final authToken = CryptoUtils.generateId();
      final verifiedChallenge = ChallengeResponse(
        challengeId: CryptoUtils.generateId(),
        challenge: CryptoUtils.generateBytes(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        sessionId: sessionId,
        isVerified: true,
        verifiedAt: DateTime.now(),
        authToken: authToken,
      );

      await redis.set(
        ns: Namespace.challenges,
        key: verifiedChallenge.challengeId,
        value: verifiedChallenge.encode(),
      );

      final res = await http.get(
        TestEnv.apiUri('/challenge/poll/${verifiedChallenge.challengeId}'),
        headers: {'cookie': 'session_id=$sessionId'},
      );
      expect(res.statusCode, equals(HttpStatus.ok));

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      expect(body['status'], equals('approved'));

      expect(res.headers['set-cookie'], isNotNull);
      expect(
        res.headers['set-cookie']!.contains('auth_token=$authToken'),
        isTrue,
      );

      final updatedChallengeData = await redis.get(
        ns: Namespace.challenges,
        key: verifiedChallenge.challengeId,
      );
      expect(updatedChallengeData, isNotNull);

      final updatedChallenge = ChallengeResponse.decode(updatedChallengeData!);
      expect(updatedChallenge.isPolled, isTrue);
    });
  });
}
