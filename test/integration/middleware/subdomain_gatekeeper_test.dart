import 'package:test/test.dart';

void main() {
  group('Subdomain gatekeeper middleware', () {
    test('returns 200 healty when no subdomain matches', () async {});

    test('returns 200 healty when client ID header is missing', () async {});

    test('returns 403 for missing api key', () async {});

    test('returns 403 for invalid api key', () async {});
  });
}
