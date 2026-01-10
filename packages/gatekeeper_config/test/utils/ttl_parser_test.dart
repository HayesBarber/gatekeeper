import 'package:test/test.dart';
import '../../lib/src/utils/ttl_parser.dart';
import '../../lib/src/exceptions/config_validation_exception.dart';

void main() {
  group('TtlParser', () {
    group('parse', () {
      test('parses seconds with unit', () {
        expect(TtlParser.parse('30s'), equals(Duration(seconds: 30)));
        expect(TtlParser.parse('45s'), equals(Duration(seconds: 45)));
      });

      test('parses minutes with unit', () {
        expect(TtlParser.parse('5m'), equals(Duration(minutes: 5)));
        expect(TtlParser.parse('60m'), equals(Duration(minutes: 60)));
      });

      test('parses hours with unit', () {
        expect(TtlParser.parse('2h'), equals(Duration(hours: 2)));
        expect(TtlParser.parse('24h'), equals(Duration(hours: 24)));
      });

      test('parses days with unit', () {
        expect(TtlParser.parse('1d'), equals(Duration(days: 1)));
        expect(TtlParser.parse('7d'), equals(Duration(days: 7)));
      });

      test('defaults to seconds when no unit', () {
        expect(TtlParser.parse('45'), equals(Duration(seconds: 45)));
        expect(TtlParser.parse('0'), equals(Duration(seconds: 0)));
      });

      test('handles whitespace', () {
        expect(TtlParser.parse(' 30s '), equals(Duration(seconds: 30)));
        expect(TtlParser.parse('\t5m\n'), equals(Duration(minutes: 5)));
      });

      test('throws for invalid format', () {
        expect(
          () => TtlParser.parse('invalid'),
          throwsA(isA<ConfigValidationException>()),
        );
        expect(
          () => TtlParser.parse('30x'),
          throwsA(isA<ConfigValidationException>()),
        );
        expect(
          () => TtlParser.parse('abc'),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('throws for empty string', () {
        expect(
          () => TtlParser.parse(''),
          throwsA(isA<ConfigValidationException>()),
        );
        expect(
          () => TtlParser.parse('   '),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('throws for negative values', () {
        expect(
          () => TtlParser.parse('-30s'),
          throwsA(isA<ConfigValidationException>()),
        );
        expect(
          () => TtlParser.parse('-5m'),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('throws for unsupported units', () {
        expect(
          () => TtlParser.parse('30w'),
          throwsA(isA<ConfigValidationException>()),
        );
        expect(
          () => TtlParser.parse('5ms'),
          throwsA(isA<ConfigValidationException>()),
        );
      });
    });
  });
}
