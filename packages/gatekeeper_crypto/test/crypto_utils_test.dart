import 'package:curveauth_dart/curveauth_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CryptoUtils.generateBytes', () {
    test('generates bytes with default length', () {
      final apiKey = CryptoUtils.generateBytes();

      expect(apiKey, isNotNull);
      expect(apiKey, isNotEmpty);
      expect(apiKey.length, equals(43));
    });

    test('generates bytes with custom length', () {
      final apiKey = CryptoUtils.generateBytes(length: 16);

      expect(apiKey, isNotNull);
      expect(apiKey, isNotEmpty);
      expect(apiKey.length, equals(22));
    });

    test('generates different bytes on multiple calls', () {
      final key1 = CryptoUtils.generateBytes();
      final key2 = CryptoUtils.generateBytes();

      expect(key1, isNot(equals(key2)));
    });

    test('generates URL-safe base64 characters only', () {
      final apiKey = CryptoUtils.generateBytes();

      final pattern = RegExp(r'^[A-Za-z0-9_-]+$');
      expect(apiKey, matches(pattern));
    });

    test('does not contain padding characters', () {
      final apiKey = CryptoUtils.generateBytes();

      expect(apiKey, isNot(contains('=')));
    });

    test('throws ArgumentError for length 0', () {
      expect(
        () => CryptoUtils.generateBytes(length: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for negative length', () {
      expect(
        () => CryptoUtils.generateBytes(length: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for length > 1024', () {
      expect(
        () => CryptoUtils.generateBytes(length: 1025),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('handles minimum valid length', () {
      final apiKey = CryptoUtils.generateBytes(length: 1);

      expect(apiKey, isNotNull);
      expect(apiKey, isNotEmpty);
      expect(apiKey.length, equals(2));
    });

    test('handles maximum valid length', () {
      final apiKey = CryptoUtils.generateBytes(length: 1024);

      expect(apiKey, isNotNull);
      expect(apiKey, isNotEmpty);
      expect(apiKey.length, equals(1366));
    });

    test('produces expected length for various inputs', () {
      final testCases = [
        (1, 2),
        (2, 3),
        (3, 4),
        (4, 6),
        (8, 11),
        (16, 22),
        (32, 43),
      ];

      for (final (input, expectedLength) in testCases) {
        final apiKey = CryptoUtils.generateBytes(length: input);
        expect(
          apiKey.length,
          equals(expectedLength),
          reason: 'Length $input should produce $expectedLength characters',
        );
      }
    });
  });

  group('CryptoUtils.generateThreeDigitCode', () {
    test('generates 3-digit code', () {
      final code = CryptoUtils.generateThreeDigitCode();

      expect(code, isNotNull);
      expect(code.length, equals(3));
    });

    test('generates numeric code only', () {
      final code = CryptoUtils.generateThreeDigitCode();

      final pattern = RegExp(r'^[0-9]{3}$');
      expect(code, matches(pattern));
    });

    test('generates codes in valid range', () {
      for (var i = 0; i < 100; i++) {
        final code = CryptoUtils.generateThreeDigitCode();
        final intValue = int.parse(code);
        expect(intValue, greaterThanOrEqualTo(100));
        expect(intValue, lessThanOrEqualTo(999));
      }
    });

    test('generates different codes on multiple calls', () {
      final codes = <String>{};
      for (var i = 0; i < 50; i++) {
        codes.add(CryptoUtils.generateThreeDigitCode());
      }
      expect(codes.length, greaterThan(1));
    });
  });

  group('CryptoUtils.generateId', () {
    test('generates valid UUID v4 format', () {
      final id = CryptoUtils.generateId();

      expect(id, isNotNull);
      expect(id, isNotEmpty);

      final pattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(id, matches(pattern));
    });

    test('generates different IDs on multiple calls', () {
      final id1 = CryptoUtils.generateId();
      final id2 = CryptoUtils.generateId();

      expect(id1, isNot(equals(id2)));
    });

    test('generates IDs with correct length', () {
      final id = CryptoUtils.generateId();
      expect(id.length, equals(36));
    });

    test('generates IDs with correct format sections', () {
      final id = CryptoUtils.generateId();
      final parts = id.split('-');

      expect(parts.length, equals(5));
      expect(parts[0].length, equals(8));
      expect(parts[1].length, equals(4));
      expect(parts[2].length, equals(4));
      expect(parts[3].length, equals(4));
      expect(parts[4].length, equals(12));
    });

    test('generates IDs with version 4 indicator', () {
      final id = CryptoUtils.generateId();
      final parts = id.split('-');

      expect(parts[2][0], equals('4'));
    });

    test('generates IDs with valid variant', () {
      final id = CryptoUtils.generateId();
      final parts = id.split('-');

      final variantChar = parts[3][0];
      expect(['8', '9', 'a', 'b'], contains(variantChar));
    });

    test('generates unique IDs across many calls', () {
      final ids = <String>{};
      for (var i = 0; i < 100; i++) {
        ids.add(CryptoUtils.generateId());
      }
      expect(ids.length, equals(100));
    });
  });
}
