import 'package:gatekeeper_crypto/gatekeeper_crypto.dart';
import 'package:test/test.dart';

void main() {
  group('WebhookVerifier', () {
    group('signature verification without prefix', () {
      test('verifies a valid GitHub webhook signature', () {
        const secret = 'It\'s a Secret to Everybody';
        const payload = 'Hello, World!';
        const expectedSignature =
            '757107ea0eb2509fc211221cce984b8a37570b6d7586c22c46f4379c8b043e17';

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: expectedSignature,
          secret: secret,
        );
        expect(isValid, isTrue);
      });

      test('fails to verify invalid GitHub webhook signature', () {
        const secret = 'It\'s a Secret to Everybody';
        const payload = 'Hello, World!';
        const invalidSignature = 'invalid_signature_hash';

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: invalidSignature,
          secret: secret,
        );
        expect(isValid, isFalse);
      });

      test('fails to verify signature with wrong secret', () {
        const secret = 'Wrong Secret';
        const payload = 'Hello, World!';
        const validSignature =
            '757107ea0eb2509fc211221cce984b8a37570b6d7586c22c46f4379c8b043e17';

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: validSignature,
          secret: secret,
        );
        expect(isValid, isFalse);
      });

      test('fails to verify signature with wrong payload', () {
        const secret = 'It\'s a Secret to Everybody';
        const payload = 'Wrong payload';
        const validSignature =
            '757107ea0eb2509fc211221cce984b8a37570b6d7586c22c46f4379c8b043e17';

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: validSignature,
          secret: secret,
        );
        expect(isValid, isFalse);
      });
    });

    group('signature verification with sha256= prefix', () {
      test('verifies a valid GitHub webhook signature with prefix', () {
        const secret = 'It\'s a Secret to Everybody';
        const payload = 'Hello, World!';
        const expectedSignature =
            'sha256=757107ea0eb2509fc211221cce984b8a37570b6d7586c22c46f4379c8b043e17';

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: expectedSignature,
          secret: secret,
        );
        expect(isValid, isTrue);
      });

      test('fails to verify invalid GitHub webhook signature with prefix', () {
        const secret = 'It\'s a Secret to Everybody';
        const payload = 'Hello, World!';
        const invalidSignature = 'sha256=invalid_signature_hash';

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: invalidSignature,
          secret: secret,
        );
        expect(isValid, isFalse);
      });

      test('fails to verify signature with wrong secret and prefix', () {
        const secret = 'Wrong Secret';
        const payload = 'Hello, World!';
        const validSignature =
            'sha256=757107ea0eb2509fc211221cce984b8a37570b6d7586c22c46f4379c8b043e17';

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: validSignature,
          secret: secret,
        );
        expect(isValid, isFalse);
      });

      test('fails to verify signature with wrong payload and prefix', () {
        const secret = 'It\'s a Secret to Everybody';
        const payload = 'Wrong payload';
        const validSignature =
            'sha256=757107ea0eb2509fc211221cce984b8a37570b6d7586c22c46f4379c8b043e17';

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: validSignature,
          secret: secret,
        );
        expect(isValid, isFalse);
      });
    });

    group('edge cases', () {
      test('handles empty signature', () {
        const secret = 'It\'s a Secret to Everybody';
        const payload = 'Hello, World!';
        const emptySignature = '';

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: emptySignature,
          secret: secret,
        );
        expect(isValid, isFalse);
      });

      test('handles empty prefix only', () {
        const secret = 'It\'s a Secret to Everybody';
        const payload = 'Hello, World!';
        const prefixOnly = 'sha256=';

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: prefixOnly,
          secret: secret,
        );
        expect(isValid, isFalse);
      });

      test('handles malformed prefix', () {
        const secret = 'It\'s a Secret to Everybody';
        const payload = 'Hello, World!';
        const malformedPrefix =
            'sha257=757107ea0eb2509fc211221cce984b8a37570b6d7586c22c46f4379c8b043e17';

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: malformedPrefix,
          secret: secret,
        );
        expect(isValid, isFalse);
      });
    });

    group('signature generation', () {
      test('generates signature that can be verified', () {
        const secret = 'It\'s a Secret to Everybody';
        const payload = 'Hello, World!';

        final signature = WebhookVerifier.generateGitHubWebhookSignature(
          payload: payload,
          secret: secret,
        );

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: signature,
          secret: secret,
        );
        expect(isValid, isTrue);
      });

      test('return false for differnt secrets', () {
        const secret = 'It\'s a Secret to Everybody';
        const secret2 = 'invalid';
        const payload = 'Hello, World!';

        final signature = WebhookVerifier.generateGitHubWebhookSignature(
          payload: payload,
          secret: secret,
        );

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: signature,
          secret: secret2,
        );
        expect(isValid, isFalse);
      });

      test('generates different signatures for different payloads', () {
        const secret = 'It\'s a Secret to Everybody';
        const payload1 = 'Hello, World!';
        const payload2 = 'Goodbye, World!';

        final signature1 = WebhookVerifier.generateGitHubWebhookSignature(
          payload: payload1,
          secret: secret,
        );
        final signature2 = WebhookVerifier.generateGitHubWebhookSignature(
          payload: payload2,
          secret: secret,
        );

        expect(signature1, isNot(equals(signature2)));
      });

      test('generates different signatures for different secrets', () {
        const secret1 = 'It\'s a Secret to Everybody';
        const secret2 = 'It\'s a Secret to Nobody';
        const payload = 'Hello, World!';

        final signature1 = WebhookVerifier.generateGitHubWebhookSignature(
          payload: payload,
          secret: secret1,
        );
        final signature2 = WebhookVerifier.generateGitHubWebhookSignature(
          payload: payload,
          secret: secret2,
        );

        expect(signature1, isNot(equals(signature2)));
      });

      test('generates signature with correct prefix', () {
        const secret = 'It\'s a Secret to Everybody';
        const payload = 'Hello, World!';

        final signature = WebhookVerifier.generateGitHubWebhookSignature(
          payload: payload,
          secret: secret,
        );

        expect(signature, startsWith('sha256='));
      });

      test('generates consistent signatures', () {
        const secret = 'It\'s a Secret to Everybody';
        const payload = 'Hello, World!';

        final signature1 = WebhookVerifier.generateGitHubWebhookSignature(
          payload: payload,
          secret: secret,
        );
        final signature2 = WebhookVerifier.generateGitHubWebhookSignature(
          payload: payload,
          secret: secret,
        );

        expect(signature1, equals(signature2));
      });

      test('handles empty payload', () {
        const secret = 'It\'s a Secret to Everybody';
        const payload = '';

        final signature = WebhookVerifier.generateGitHubWebhookSignature(
          payload: payload,
          secret: secret,
        );

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: signature,
          secret: secret,
        );
        expect(isValid, isTrue);
      });

      test('handles empty secret', () {
        const secret = '';
        const payload = 'Hello, World!';

        final signature = WebhookVerifier.generateGitHubWebhookSignature(
          payload: payload,
          secret: secret,
        );

        final isValid = WebhookVerifier.verifyGitHubWebhook(
          payload: payload,
          signature: signature,
          secret: secret,
        );
        expect(isValid, isTrue);
      });
    });
  });
}
