import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

class RequestUtil {
  bool isBrowserRequest(Request request) {
    final headers = request.headers;

    const secFetchHeaders = {
      'sec-fetch-mode',
      'sec-fetch-site',
      'sec-fetch-dest',
    };

    if (headers.keys.any((h) => secFetchHeaders.contains(h.toLowerCase()))) {
      return true;
    }

    final accept = headers[HttpHeaders.acceptHeader];
    if (accept != null && accept.contains('text/html')) {
      return true;
    }

    final ua = headers[HttpHeaders.userAgentHeader]?.toLowerCase();
    if (ua != null) {
      return ua.contains('mozilla') ||
          ua.contains('chrome') ||
          ua.contains('safari') ||
          ua.contains('firefox') ||
          ua.contains('edge');
    }

    return false;
  }
}
