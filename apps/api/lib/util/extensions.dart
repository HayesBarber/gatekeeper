import 'package:gatekeeper/constants/headers.dart';

extension DateTimeDiff on DateTime {
  /// Duration from [start] to this DateTime (this - start) in ms
  int since(DateTime start) => difference(start).inMilliseconds;
}

/// header extensions from dart_frog_auth
extension Headers on Map<String, String> {
  String? authorization(String type) {
    final value = this['Authorization']?.split(' ');

    if (value != null && value.length == 2 && value.first == type) {
      return value.last;
    }

    return null;
  }

  String? bearer() => authorization('Bearer');

  Map<String, String>? cookies() {
    final cookieString = this[cookie];
    if (cookieString == null) return null;

    final cookiesEntries = cookieString.split('; ').map((cookie) {
      final [key, value] = cookie.split('=');
      return MapEntry(key, value);
    });

    return Map.fromEntries(cookiesEntries);
  }
}
