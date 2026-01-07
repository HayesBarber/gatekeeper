import 'dart:io';

import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'test_env.dart';

class ItUtil {
  static Future<ChallengeResponse> getChallenge() async {
    final challengeRes = await http.post(
      TestEnv.apiUri('/challenge'),
    );
    expect(challengeRes.statusCode, equals(HttpStatus.ok));
    expect(challengeRes.body, isNotEmpty);
    final challenge = ChallengeResponse.decode(challengeRes.body);
    expect(challenge.challengeId, isNotEmpty);
    expect(challenge.challenge, isNotEmpty);
    expect(challenge.expiresAt, isNotNull);
    return challenge;
  }
}
