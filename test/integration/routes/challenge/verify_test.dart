import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../util/test_env.dart';

void main() {
  group('POST /challenge/verify', () {
    test('responds with a 200 and greeting.', () async {
      final res = await http.get(
        TestEnv.apiUri('/challenge/verify'),
      );
      expect(res.statusCode, 200);
      expect(res.body, 'This is a new route!');
    });
  });
}
