import 'package:test/test.dart';
import '../../lib/src/utils/subdomain_validator.dart';
import '../../lib/src/exceptions/config_validation_exception.dart';

void main() {
  group('SubdomainValidator', () {
    group('isValid', () {
      test('returns true for valid subdomains', () {
        expect(SubdomainValidator.isValid('api'), isTrue);
        expect(SubdomainValidator.isValid('api123'), isTrue);
        expect(SubdomainValidator.isValid('test-subdomain'), isTrue);
        expect(SubdomainValidator.isValid('a'), isTrue); // minimum length
        expect(SubdomainValidator.isValid('a' * 63), isTrue); // maximum length
      });

      test('returns false for invalid subdomains', () {
        expect(SubdomainValidator.isValid(''), isFalse); // empty
        expect(
          SubdomainValidator.isValid('-subdomain'),
          isFalse,
        ); // starts with hyphen
        expect(
          SubdomainValidator.isValid('subdomain-'),
          isFalse,
        ); // ends with hyphen
        expect(
          SubdomainValidator.isValid('sub.domain'),
          isFalse,
        ); // contains period
        expect(
          SubdomainValidator.isValid('sub_domain'),
          isFalse,
        ); // contains underscore
        expect(SubdomainValidator.isValid('Subdomain'), isFalse); // uppercase
        expect(SubdomainValidator.isValid('a' * 64), isFalse); // too long
        expect(SubdomainValidator.isValid('123'), isFalse); // starts with digit
      });
    });

    group('validate', () {
      test('passes for valid subdomains', () {
        expect(
          () => SubdomainValidator.validate('api', 'test'),
          returnsNormally,
        );
        expect(
          () => SubdomainValidator.validate('test-subdomain', 'test'),
          returnsNormally,
        );
      });

      test('throws for invalid subdomains', () {
        expect(
          () => SubdomainValidator.validate('-invalid', 'test'),
          throwsA(isA<ConfigValidationException>()),
        );
        expect(
          () => SubdomainValidator.validate('sub.domain', 'test'),
          throwsA(isA<ConfigValidationException>()),
        );
      });
    });
  });
}
