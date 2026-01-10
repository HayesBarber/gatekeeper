import 'package:gatekeeper/util/path_matcher.dart';
import 'package:test/test.dart';

void main() {
  group('PathMatcher', () {
    group('matches', () {
      test('exact path match', () {
        expect(PathMatcher.matches('/admin/users', '/admin/users'), isTrue);
        expect(PathMatcher.matches('/admin/users', '/admin/user'), isFalse);
      });

      test('wildcard * matches any sequence', () {
        expect(PathMatcher.matches('/admin/*', '/admin/users'), isTrue);
        expect(PathMatcher.matches('/admin/*', '/admin/settings'), isTrue);
        expect(PathMatcher.matches('/admin/*', '/admin'), isFalse);
        expect(PathMatcher.matches('/admin/*', '/api/users'), isFalse);
      });

      test('wildcard * at beginning', () {
        expect(PathMatcher.matches('*/admin', '/api/admin'), isTrue);
        expect(PathMatcher.matches('*/admin', '/web/admin'), isTrue);
        expect(PathMatcher.matches('*/admin', '/admin'), isTrue);
      });

      test('wildcard * in middle', () {
        expect(PathMatcher.matches('/api/*/users', '/api/v1/users'), isTrue);
        expect(PathMatcher.matches('/api/*/users', '/api/v2/users'), isTrue);
        expect(PathMatcher.matches('/api/*/users', '/api/users'), isFalse);
      });

      test('multiple wildcards', () {
        expect(
          PathMatcher.matches('/api/*/secret/*', '/api/v1/secret/data'),
          isTrue,
        );
        expect(
          PathMatcher.matches('/api/*/secret/*', '/api/v2/secret/info'),
          isTrue,
        );
        expect(
          PathMatcher.matches('/api/*/secret/*', '/api/v1/public/data'),
          isFalse,
        );
      });

      test('wildcard ? matches single character', () {
        expect(PathMatcher.matches('/api/v?/users', '/api/v1/users'), isTrue);
        expect(PathMatcher.matches('/api/v?/users', '/api/v2/users'), isTrue);
        expect(PathMatcher.matches('/api/v?/users', '/api/v10/users'), isFalse);
        expect(PathMatcher.matches('/api/v?/users', '/api/v/users'), isFalse);
      });

      test('single * matches everything', () {
        expect(PathMatcher.matches('*', '/any/path'), isTrue);
        expect(PathMatcher.matches('*', '/'), isTrue);
        expect(PathMatcher.matches('*', ''), isTrue);
      });
    });

    group('isPathBlacklisted', () {
      test('returns true when path matches any pattern', () {
        final patterns = ['/admin/*', '/health', '/debug'];
        expect(PathMatcher.isPathBlacklisted(patterns, '/admin/users'), isTrue);
        expect(PathMatcher.isPathBlacklisted(patterns, '/health'), isTrue);
        expect(PathMatcher.isPathBlacklisted(patterns, '/debug'), isTrue);
      });

      test('returns false when path matches no patterns', () {
        final patterns = ['/admin/*', '/health', '/debug'];
        expect(PathMatcher.isPathBlacklisted(patterns, '/api/users'), isFalse);
        expect(PathMatcher.isPathBlacklisted(patterns, '/status'), isFalse);
        expect(PathMatcher.isPathBlacklisted(patterns, '/admin'), isFalse);
      });

      test('handles empty patterns list', () {
        final patterns = <String>[];
        expect(
          PathMatcher.isPathBlacklisted(patterns, '/admin/users'),
          isFalse,
        );
        expect(
          PathMatcher.isPathBlacklisted(patterns, '/any/path'),
          isFalse,
        );
      });
    });
  });
}
