import 'package:gatekeeper/util/cookie_util.dart';
import 'package:test/test.dart';

void main() {
  group('CookieUtil', () {
    group('buildSetCookieHeader', () {
      test('builds basic cookie header with default security attributes', () {
        final header = CookieUtil.buildSetCookieHeader('test', 'value');

        expect(header, equals('test=value; HttpOnly; Secure; SameSite=Strict'));
      });

      test('builds cookie with all attributes', () {
        final expires = DateTime.utc(2023, 12, 25, 10, 30);
        final header = CookieUtil.buildSetCookieHeader(
          'session',
          'abc123',
          expires: expires,
          domain: 'example.com',
          path: '/',
          maxAge: 3600,
          httpOnly: false,
          secure: false,
          sameSite: 'Lax',
        );

        expect(header, contains('session=abc123'));
        expect(header, contains('Expires=Mon, 25 Dec 2023 10:30:00 GMT'));
        expect(header, contains('Domain=example.com'));
        expect(header, contains('Path=/'));
        expect(header, contains('Max-Age=3600'));
        expect(header, isNot(contains('HttpOnly')));
        expect(header, isNot(contains('Secure')));
        expect(header, contains('SameSite=Lax'));
      });

      test('builds cookie with only expiration', () {
        final expires = DateTime.now().add(const Duration(hours: 24));
        final header = CookieUtil.buildSetCookieHeader(
          'auth',
          'token',
          expires: expires,
        );

        expect(header, contains('auth=token'));
        expect(header, contains('Expires='));
        expect(header, contains('HttpOnly'));
        expect(header, contains('Secure'));
        expect(header, contains('SameSite=Strict'));
        expect(header, isNot(contains('Domain=')));
        expect(header, isNot(contains('Path=')));
        expect(header, isNot(contains('Max-Age=')));
      });

      test('builds cookie with domain and path only', () {
        final header = CookieUtil.buildSetCookieHeader(
          'user_pref',
          'dark',
          domain: 'app.example.com',
          path: '/api',
        );

        expect(header, contains('user_pref=dark'));
        expect(header, contains('Domain=app.example.com'));
        expect(header, contains('Path=/api'));
        expect(header, contains('HttpOnly'));
        expect(header, contains('Secure'));
        expect(header, contains('SameSite=Strict'));
      });

      test('builds cookie with max-age only', () {
        final header = CookieUtil.buildSetCookieHeader(
          'rate_limit',
          '100',
          maxAge: 7200,
        );

        expect(header, contains('rate_limit=100'));
        expect(header, contains('Max-Age=7200'));
        expect(header, contains('HttpOnly'));
        expect(header, contains('Secure'));
        expect(header, contains('SameSite=Strict'));
      });

      test('handles empty values correctly', () {
        final header = CookieUtil.buildSetCookieHeader('empty', '');

        expect(header, equals('empty=; HttpOnly; Secure; SameSite=Strict'));
      });

      test('handles special characters in values', () {
        final header =
            CookieUtil.buildSetCookieHeader('data', 'abc:123&xyz=value');

        expect(header, contains('data=abc:123&xyz=value'));
      });

      test('handles different SameSite values', () {
        final strict = CookieUtil.buildSetCookieHeader(
          'strict',
          'value',
        );
        final none = CookieUtil.buildSetCookieHeader(
          'none',
          'value',
          sameSite: 'None',
        );

        expect(strict, contains('SameSite=Strict'));
        expect(none, contains('SameSite=None'));
      });
    });

    group('_formatExpires', () {
      test('formats UTC datetime correctly', () {
        final expires = DateTime.utc(2023, 12, 25, 15, 30, 45);
        final header = CookieUtil.buildSetCookieHeader(
          'test',
          'value',
          expires: expires,
        );

        expect(header, contains('Expires=Mon, 25 Dec 2023 15:30:45 GMT'));
      });

      test('formats local datetime correctly (converts to GMT)', () {
        final expires = DateTime(2023, 12, 25, 15, 30, 45);
        final header = CookieUtil.buildSetCookieHeader(
          'test',
          'value',
          expires: expires,
        );

        // Should contain GMT formatted date
        expect(header, contains('Expires='));
        expect(header, contains('Mon, 25 Dec 2023'));
        expect(header, contains('GMT'));
      });

      test('handles edge case datetime', () {
        final expires = DateTime.utc(2000);
        final header = CookieUtil.buildSetCookieHeader(
          'y2k',
          'test',
          expires: expires,
        );

        expect(header, contains('Expires=Sat, 01 Jan 2000 00:00:00 GMT'));
      });
    });

    group('edge cases and validation', () {
      test('handles long cookie names and values', () {
        final longName = 'a' * 100;
        final longValue = 'b' * 4000;
        final header = CookieUtil.buildSetCookieHeader(longName, longValue);

        expect(header, startsWith('$longName=$longValue'));
        expect(header, contains('HttpOnly; Secure; SameSite=Strict'));
      });

      test('handles cookies with underscores in names', () {
        final header = CookieUtil.buildSetCookieHeader('user_id', '12345');

        expect(header, contains('user_id=12345'));
      });

      test('handles domain with subdomain', () {
        final header = CookieUtil.buildSetCookieHeader(
          'session',
          'abc',
          domain: 'api.app.example.com',
        );

        expect(header, contains('Domain=api.app.example.com'));
      });

      test('handles path with nested routes', () {
        final header = CookieUtil.buildSetCookieHeader(
          'token',
          'xyz',
          path: '/api/v2/auth',
        );

        expect(header, contains('Path=/api/v2/auth'));
      });

      test('handles zero max-age', () {
        final header = CookieUtil.buildSetCookieHeader(
          'immediate',
          'expire',
          maxAge: 0,
        );

        expect(header, contains('Max-Age=0'));
      });

      test('handles large max-age value', () {
        final header = CookieUtil.buildSetCookieHeader(
          'longlived',
          'value',
          maxAge: 31536000,
        );

        expect(header, contains('Max-Age=31536000'));
      });
    });

    group('RFC compliance', () {
      test('orders attributes correctly', () {
        final expires = DateTime.utc(2023, 12, 25, 10, 30);
        final header = CookieUtil.buildSetCookieHeader(
          'test',
          'value',
          expires: expires,
          domain: 'example.com',
          path: '/',
          maxAge: 3600,
        );

        // Order should be: name=value, then attributes
        expect(header, startsWith('test=value;'));

        // All expected attributes should be present
        expect(header, contains('Expires='));
        expect(header, contains('Domain=example.com'));
        expect(header, contains('Path=/'));
        expect(header, contains('Max-Age=3600'));
        expect(header, contains('HttpOnly'));
        expect(header, contains('Secure'));
        expect(header, contains('SameSite=Strict'));
      });

      test('separates attributes with semicolon and space', () {
        final header = CookieUtil.buildSetCookieHeader('name', 'value');

        expect(header, contains('; '));
        expect(header, isNot(endsWith(';')));
      });

      test('handles None SameSite for cross-site cookies', () {
        final header = CookieUtil.buildSetCookieHeader(
          'cross_site',
          'value',
          sameSite: 'None',
        );

        expect(header, contains('SameSite=None'));
      });
    });
  });
}
