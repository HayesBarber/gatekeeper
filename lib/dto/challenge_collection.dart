import 'dart:convert';

import 'package:gatekeeper/dto/challenge_response.dart';

class ChallengeCollection {
  ChallengeCollection({
    required this.challenges,
  });

  factory ChallengeCollection.fromJson(Map<String, dynamic> json) {
    final challengesMap = <String, ChallengeResponse>{};

    if (json.containsKey('challenges')) {
      final challengesData = json['challenges'] as Map<String, dynamic>;

      for (final entry in challengesData.entries) {
        challengesMap[entry.key] =
            ChallengeResponse.fromJson(entry.value as Map<String, dynamic>);
      }
    } else {
      final challenge = ChallengeResponse.fromJson(json);
      challengesMap[challenge.challengeId] = challenge;
    }

    return ChallengeCollection(
      challenges: challengesMap,
    );
  }

  factory ChallengeCollection.decode(String json) =>
      ChallengeCollection.fromJson(jsonDecode(json) as Map<String, dynamic>);

  factory ChallengeCollection.fromSingleChallenge(ChallengeResponse challenge) {
    return ChallengeCollection(
      challenges: {challenge.challengeId: challenge},
    );
  }

  factory ChallengeCollection.empty() {
    return ChallengeCollection(challenges: {});
  }

  final Map<String, ChallengeResponse> challenges;

  void addChallenge(ChallengeResponse challenge) {
    challenges[challenge.challengeId] = challenge;
  }

  ChallengeResponse? getChallenge(String challengeId) {
    return challenges[challengeId];
  }

  ChallengeCollection cleaned() {
    final now = DateTime.now().toUtc();
    final cleanedChallenges = <String, ChallengeResponse>{};

    for (final entry in challenges.entries) {
      final challenge = entry.value;
      if (!challenge.expiresAt.isBefore(now) && !challenge.isPolled) {
        cleanedChallenges[entry.key] = challenge;
      }
    }

    return ChallengeCollection(
      challenges: cleanedChallenges,
    );
  }

  bool get shouldDelete => challenges.isEmpty;

  Map<String, dynamic> toJson() {
    final challengesMap = <String, dynamic>{};

    for (final entry in challenges.entries) {
      challengesMap[entry.key] = entry.value.toJson();
    }

    return {
      'challenges': challengesMap,
    };
  }

  String encode() => jsonEncode(toJson());
}
