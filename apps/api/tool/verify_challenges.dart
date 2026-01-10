import 'dart:convert';

import 'package:args/args.dart';
import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/redis/shorebird_redis_client.dart';
import 'package:gatekeeper_core/gatekeeper_core.dart';
import 'package:http/http.dart' as http;

class Config {
  Config({
    required this.deviceId,
    required this.baseUrl,
    required this.redisHost,
  });
  final String deviceId;
  final String baseUrl;
  final String redisHost;
}

Future<Map<String, dynamic>> runVerificationFlow(Config config) async {
  final stopwatch = Stopwatch()..start();
  final timings = <String, dynamic>{};

  final keyPair = ECCKeyPair.generate();
  final publicKeyBase64 = keyPair.exportPublicKeyRawBase64();

  final redis = await ShorebirdRedisClient.connect(host: config.redisHost);

  try {
    await redis.set(
      ns: Namespace.devices,
      key: config.deviceId,
      value: publicKeyBase64,
    );

    timings['redis_setup'] = stopwatch.elapsedMilliseconds;

    final challengeResponse = await http.post(
      Uri.parse('${config.baseUrl}/challenge'),
      headers: {'Content-Type': 'application/json'},
    );

    final challengeData =
        jsonDecode(challengeResponse.body) as Map<String, dynamic>;
    timings['challenge_created'] = DateTime.now().toIso8601String();

    final challenge = challengeData['challenge'] as String;
    final signature = await keyPair.createSignature(challenge);

    timings['challenge_signed'] = stopwatch.elapsedMilliseconds;

    final verificationRequest = ChallengeVerificationRequest(
      challengeId: challengeData['challenge_id'] as String,
      signature: signature,
      deviceId: config.deviceId,
    );

    final verificationResponse = await http.post(
      Uri.parse('${config.baseUrl}/challenge/verify'),
      body: verificationRequest.encode(),
      headers: {'Content-Type': 'application/json'},
    );

    timings['verification_completed'] = DateTime.now().toIso8601String();
    timings['total_duration_ms'] = stopwatch.elapsedMilliseconds;

    final verificationData =
        ChallengeVerificationResponse.decode(verificationResponse.body);
    final apiKey = verificationData.apiKey;

    final challengesRes = await http.get(
      Uri.parse('${config.baseUrl}/challenge'),
      headers: {
        'authorization': 'Bearer $apiKey',
      },
    );
    final challenges =
        (jsonDecode(challengesRes.body) as List).cast<Map<String, dynamic>>();

    final additionalResults = <Map<String, dynamic>>[];
    var verifiedCount = 0;
    var failedCount = 0;

    for (final challenge in challenges) {
      try {
        final signature =
            await keyPair.createSignature(challenge['challenge'] as String);
        final verificationRequest = ChallengeVerificationRequest(
          challengeId: challenge['challenge_id'] as String,
          signature: signature,
          deviceId: config.deviceId,
        );

        final verificationResponse = await http.post(
          Uri.parse('${config.baseUrl}/challenge/verify'),
          body: verificationRequest.encode(),
          headers: {'Content-Type': 'application/json'},
        );

        if (verificationResponse.statusCode == 200) {
          verifiedCount++;
          additionalResults.add({
            'challenge_id': challenge['challenge_id'],
            'success': true,
            'error': null,
          });
        } else {
          failedCount++;
          additionalResults.add({
            'challenge_id': challenge['challenge_id'],
            'success': false,
            'error': 'HTTP ${verificationResponse.statusCode}',
          });
        }
      } catch (e) {
        failedCount++;
        additionalResults.add({
          'challenge_id': challenge['challenge_id'],
          'success': false,
          'error': e.toString(),
        });
      }
    }

    final allAdditionalSucceeded = failedCount == 0 && challenges.isNotEmpty;

    final overallSuccess = allAdditionalSucceeded;

    return {
      'success': overallSuccess,
      'initial_challenge': {
        'challenge_id': challengeData['challenge_id'],
        'challenge': challenge,
        'challenge_code': challengeData['challenge_code'],
        'expires_at': challengeData['expires_at'],
      },
      'additional_challenges': {
        'total': challenges.length,
        'verified': verifiedCount,
        'failed': failedCount,
        'results': additionalResults,
      },
      'verification': {
        'api_key': verificationData.apiKey,
        'expires_at': verificationData.expiresAt.toIso8601String(),
      },
      'device': {
        'device_id': config.deviceId,
        'public_key': publicKeyBase64,
      },
      'timing': timings,
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
      'step': 'verification_flow',
      'timing': timings,
    };
  } finally {
    try {
      await redis.delete(ns: Namespace.devices, key: config.deviceId);
    } finally {
      await redis.close();
    }
  }
}

Config parseArgs(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('device-id', defaultsTo: 'test-user', help: 'Device identifier')
    ..addOption(
      'base-url',
      defaultsTo: 'http://localhost:8080',
      help: 'API base URL',
    )
    ..addOption('redis-host', defaultsTo: '127.0.0.1', help: 'Redis host');

  final results = parser.parse(arguments);

  return Config(
    deviceId: results['device-id'] as String,
    baseUrl: results['base-url'] as String,
    redisHost: results['redis-host'] as String,
  );
}

void outputJsonResult(Map<String, dynamic> result) {
  print(jsonEncode(result));
}

void main(List<String> arguments) async {
  final config = parseArgs(arguments);
  final result = await runVerificationFlow(config);
  outputJsonResult(result);
}
