import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/util/request_util.dart';
import 'package:test/test.dart';

void main() {
  group('RequestUtil.isBrowserRequest', () {
    late RequestUtil util;

    setUp(() {
      util = RequestUtil();
    });

    test('returns true when Sec-Fetch headers are present', () {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/'),
        headers: {
          'Sec-Fetch-Mode': 'navigate',
        },
      );

      expect(util.isBrowserRequest(request), isTrue);
    });

    test('returns true when Accept contains text/html', () {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/'),
        headers: {
          HttpHeaders.acceptHeader: 'text/html,application/xhtml+xml',
        },
      );

      expect(util.isBrowserRequest(request), isTrue);
    });

    test('returns true when User-Agent looks like a browser', () {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/'),
        headers: {
          HttpHeaders.userAgentHeader:
              'Mozilla/5.0 (Macintosh; Intel Mac OS X)',
        },
      );

      expect(util.isBrowserRequest(request), isTrue);
    });

    test('returns false for typical API client headers', () {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/'),
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.userAgentHeader: 'curl/8.4.0',
        },
      );

      expect(util.isBrowserRequest(request), isFalse);
    });

    test('returns false when no identifying headers are present', () {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/'),
      );

      expect(util.isBrowserRequest(request), isFalse);
    });
  });
}
