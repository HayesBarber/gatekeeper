import 'dart:convert';
import 'dart:io';

import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/dto/challenge_response.dart';
import 'package:gatekeeper/dto/challenge_verification_request.dart';
import 'package:gatekeeper/dto/challenge_verification_response.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'test_env.dart';

class ItUtil {
  static Future<ChallengeResponse> getChallenge() async {
    final challengeRes = await http.post(
      TestEnv.apiUri('/challenge'),
      headers: {
        headerRequestorId: TestEnv.clientId,
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

  static Future<ChallengeVerificationResponse> verifyChallengeAndGetApiKey(
    String challengeId,
    String challenge,
  ) async {
    final keyPair = ECCKeyPair.fromJson(
      Map<String, String>.from(
        jsonDecode(TestEnv.keyPairJson) as Map<String, dynamic>,
      ),
    );
    final signature = await keyPair.createSignature(challenge);
    final res = await http.post(
      TestEnv.apiUri('/challenge/verify'),
      headers: {
        headerRequestorId: TestEnv.clientId,
      },
      body: ChallengeVerificationRequest(
        challengeId: challengeId,
        signature: signature,
      ).encode(),
    );
    expect(res.statusCode, equals(HttpStatus.ok));
    final apiKeyResponse = ChallengeVerificationResponse.decode(res.body);
    return apiKeyResponse;
  }
}
