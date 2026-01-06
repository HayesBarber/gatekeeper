import 'dart:convert';

import 'package:gatekeeper/dto/challenge_collection.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:gatekeeper/redis/redis_client.dart';

class ChallengeHelper {
  static Future<ChallengeCollection?> getChallengeCollection(
    RedisClientBase redis,
    String clientId,
  ) async {
    final data = await redis.get(
      ns: Namespace.challenges,
      key: clientId,
    );

    if (data == null) return null;

    try {
      final jsonData = jsonDecode(data) as Map<String, dynamic>;

      if (jsonData.containsKey('challenges')) {
        return ChallengeCollection.fromJson(jsonData);
      } else {
        final challenge = ChallengeResponse.fromJson(jsonData);
        return ChallengeCollection.fromSingleChallenge(challenge);
      }
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveChallengeCollection(
    RedisClientBase redis,
    String clientId,
    ChallengeCollection collection,
  ) async {
    final cleanedCollection = collection.cleaned();

    if (cleanedCollection.shouldDelete) {
      await redis.delete(
        ns: Namespace.challenges,
        key: clientId,
      );
    } else {
      await redis.set(
        ns: Namespace.challenges,
        key: clientId,
        value: cleanedCollection.encode(),
      );
    }
  }
}
