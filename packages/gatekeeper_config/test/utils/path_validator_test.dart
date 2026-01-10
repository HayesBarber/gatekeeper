import 'package:test/test.dart';
import '../../lib/src/utils/path_validator.dart';
import '../../lib/src/exceptions/config_validation_exception.dart';

void main() {
  group('PathValidator', () {
    group('isValid', () {
      test('returns true for valid paths', () {
        expect(PathValidator.isValid('/admin'), isTrue);
        expect(PathValidator.isValid('/admin/*'), isTrue);
        expect(PathValidator.isValid('/users/*/profile'), isTrue);
        expect(PathValidator.isValid('/api/**'), isTrue);
        expect(PathValidator.isValid('/'), isTrue);
        expect(PathValidator.isValid('/a/b/c'), isTrue);
      });

      test('returns false for invalid paths', () {
        expect(PathValidator.isValid(''), isFalse); // empty
        expect(PathValidator.isValid('admin'), isFalse); // no leading slash
        expect(PathValidator.isValid('//admin'), isFalse); // double slash
        expect(PathValidator.isValid('/admin/'), isFalse); // trailing slash
        expect(PathValidator.isValid('/admin//users'), isFalse); // double slash
      });
    });

    group('validate', () {
      test('passes for valid paths', () {
        expect(
          () => PathValidator.validate('/admin/*', 'test'),
          returnsNormally,
        );
        expect(
          () => PathValidator.validate('/api/**', 'test'),
          returnsNormally,
        );
      });

      test('throws for invalid paths', () {
        expect(
          () => PathValidator.validate('admin', 'test'),
          throwsA(isA<ConfigValidationException>()),
        );
        expect(
          () => PathValidator.validate('/admin/', 'test'),
          throwsA(isA<ConfigValidationException>()),
        );
      });
    });
  });
}
