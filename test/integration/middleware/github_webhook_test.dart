import 'dart:convert';
import 'dart:io';

import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../util/test_env.dart';

void main() {
  group('GitHub webhook middleware', () {
    test('returns 200 healthy when no subdomain matches', () async {
      final res = await http.get(
        TestEnv.apiUri('/health'),
      );
      expect(res.statusCode, equals(HttpStatus.ok));
      expect(res.body, equals('healthy'));
    });

    test('returns 401 for missing signature header', () async {
      final res = await http.get(
        TestEnv.apiUri('/echo'),
        headers: TestEnv.headersWithSubdomain(
          'github',
        ),
      );
      expect(res.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns 401 for invalid signature', () async {
      final res = await http.get(
        TestEnv.apiUri('/echo'),
        headers: {
          ...TestEnv.headersWithSubdomain(
            'github',
          ),
          hubSignature: 'invalid',
        },
      );
      expect(res.statusCode, equals(HttpStatus.unauthorized));
    });

    test(
      'returns 200 from upstream for valid GitHub webhook signature',
      () async {
        const payload = 'hello world';
        final secret = TestEnv.githubWebhookSecret;
        final signature = WebhookVerifier.generateGitHubWebhookSignature(
          payload: payload,
          secret: secret,
        );
        final res = await http.post(
          TestEnv.apiUri('/notify'),
          headers: {
            ...TestEnv.headersWithSubdomain(
              'github',
            ),
            hubSignature: signature,
          },
          body: payload,
        );
        expect(res.statusCode, equals(HttpStatus.ok));
        final jsonBody = jsonDecode(res.body) as Map<String, dynamic>;
        expect(jsonBody['method'], equals('POST'));
        expect(jsonBody['path'], equals('/notify'));
      },
    );

    test('handles empty body with valid signature', () async {
      const payload = '';
      final secret = TestEnv.githubWebhookSecret;
      final signature = WebhookVerifier.generateGitHubWebhookSignature(
        payload: payload,
        secret: secret,
      );
      final res = await http.post(
        TestEnv.apiUri('/notify'),
        headers: {
          ...TestEnv.headersWithSubdomain(
            'github',
          ),
          hubSignature: signature,
        },
        body: payload,
      );
      expect(res.statusCode, equals(HttpStatus.ok));
      final jsonBody = jsonDecode(res.body) as Map<String, dynamic>;
      expect(jsonBody['method'], equals('POST'));
      expect(jsonBody['path'], equals('/notify'));
      expect(jsonBody['body'], equals(''));
    });

    test('handles large payload with valid signature', () async {
      final largePayload = 'x' * 100000;
      final secret = TestEnv.githubWebhookSecret;
      final signature = WebhookVerifier.generateGitHubWebhookSignature(
        payload: largePayload,
        secret: secret,
      );
      final res = await http.post(
        TestEnv.apiUri('/notify'),
        headers: {
          ...TestEnv.headersWithSubdomain(
            'github',
          ),
          hubSignature: signature,
        },
        body: largePayload,
      );
      expect(res.statusCode, equals(HttpStatus.ok));
      final jsonBody = jsonDecode(res.body) as Map<String, dynamic>;
      expect(jsonBody['method'], equals('POST'));
      expect(jsonBody['path'], equals('/notify'));
      expect(jsonBody['body'], equals(largePayload));
    });
  });
}
