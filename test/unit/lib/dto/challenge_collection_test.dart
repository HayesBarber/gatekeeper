import 'dart:convert';

import 'package:gatekeeper/dto/challenge_collection.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:test/test.dart';

void main() {
  group('ChallengeCollection', () {
    test('should handle multiple challenges', () async {
      final collection = ChallengeCollection.empty();

      final challenge1 = ChallengeResponse.random();
      final challenge2 = ChallengeResponse.random();

      collection
        ..addChallenge(challenge1)
        ..addChallenge(challenge2);

      expect(collection.challenges.length, equals(2));
      expect(
        collection.getChallenge(challenge1.challengeId),
        equals(challenge1),
      );
      expect(
        collection.getChallenge(challenge2.challengeId),
        equals(challenge2),
      );
    });

    test('should clean expired challenges', () async {
      final collection = ChallengeCollection.empty();

      final validChallenge = ChallengeResponse(
        challengeId: 'valid',
        challenge: 'valid-challenge',
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
      );

      final expiredChallenge = ChallengeResponse(
        challengeId: 'expired',
        challenge: 'expired-challenge',
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );

      collection
        ..addChallenge(validChallenge)
        ..addChallenge(expiredChallenge);

      expect(collection.challenges.length, equals(2));

      final cleaned = collection.cleaned();

      expect(cleaned.challenges.length, equals(1));
      expect(cleaned.getChallenge('valid'), isNotNull);
      expect(cleaned.getChallenge('expired'), isNull);
    });

    test('should mark challenge as verified', () async {
      final challenge = ChallengeResponse(
        challengeId: 'test',
        challenge: 'test-challenge',
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
      );

      expect(challenge.isVerified, isFalse);
      expect(challenge.apiKey, isNull);

      final verifiedChallenge =
          challenge.markAsVerified(apiKey: 'test-api-key');

      expect(verifiedChallenge.isVerified, isTrue);
      expect(verifiedChallenge.apiKey, equals('test-api-key'));
      expect(verifiedChallenge.verifiedAt, isNotNull);
    });

    test('should serialize and deserialize correctly', () async {
      final collection = ChallengeCollection.empty();

      final challenge = ChallengeResponse(
        challengeId: 'test',
        challenge: 'test-challenge',
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
        isVerified: true,
        verifiedAt: DateTime.now().toUtc(),
        apiKey: 'test-api-key',
      );

      collection.addChallenge(challenge);

      final json = collection.encode();
      final decoded = ChallengeCollection.decode(json);

      expect(decoded.challenges.length, equals(1));
      final decodedChallenge = decoded.getChallenge('test')!;
      expect(decodedChallenge.challengeId, equals(challenge.challengeId));
      expect(decodedChallenge.challenge, equals(challenge.challenge));
      expect(decodedChallenge.isVerified, equals(challenge.isVerified));
      expect(decodedChallenge.apiKey, equals(challenge.apiKey));
    });

    test('should migrate from single challenge format', () async {
      final singleChallenge = ChallengeResponse(
        challengeId: 'single',
        challenge: 'single-challenge',
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
      );

      final singleChallengeJson = singleChallenge.encode();
      final jsonData = jsonDecode(singleChallengeJson) as Map<String, dynamic>;

      expect(jsonData.containsKey('challenges'), isFalse);

      final collection = ChallengeCollection.fromJson(jsonData);

      expect(collection.challenges.length, equals(1));
      expect(collection.getChallenge('single'), isNotNull);
    });
  });
}
