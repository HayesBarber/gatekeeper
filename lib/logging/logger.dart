import 'dart:convert';
import 'dart:math';

import 'package:gatekeeper/logging/wide_event.dart';
import 'package:uuid/uuid.dart';

class Logger {
  factory Logger.init({
    required bool loggingEnabled,
    required int slowRequestThresholdMs,
    required double successfulSampleRate,
  }) {
    _instance = Logger._(
      loggingEnabled: loggingEnabled,
      slowRequestThresholdMs: slowRequestThresholdMs,
      successfulSampleRate: successfulSampleRate,
    );
    return _instance!;
  }
  Logger._({
    required this.loggingEnabled,
    required this.slowRequestThresholdMs,
    required this.successfulSampleRate,
  });

  static Logger? _instance;
  final bool loggingEnabled;
  final int slowRequestThresholdMs;
  final double successfulSampleRate;
  final Random _random = Random();
  final Uuid _uuid = const Uuid();

  static Logger instance() {
    if (_instance == null) {
      throw StateError('Logger not initialized. Call init() first.');
    }
    return _instance!;
  }

  void emitEvent(WideEvent event) {
    if (!shouldSample(event)) {
      return;
    }

    try {
      final jsonString =
          const JsonEncoder.withIndent('').convert(event.toJson());
      print(jsonString);
    } catch (e) {
      print(
        // ignore: lines_longer_than_80_chars
        '{"ts":${DateTime.now().millisecondsSinceEpoch},"error":"logging_failed","details":"$e"}',
      );
    }
  }

  bool shouldSample(WideEvent event) {
    // errors
    if (event.response.statusCode >= 400) return true;
    if (event.error != null) return true;

    // authentication failures
    if (event.authentication?.apiKeyValid == false) return true;

    // webhook signature failures
    if (event.webhook?.signatureValid == false) return true;

    // slow requests
    if (event.response.durationMs > slowRequestThresholdMs) return true;

    // upstream failures
    if (event.upstream?.forwarded == false) return true;

    // path blacklist rejections
    if (event.authentication?.pathBlacklisted ?? false) return true;

    // expired API key attempts
    if (event.authentication?.keyExpired ?? false) return true;

    return _random.nextDouble() < successfulSampleRate;
  }

  String generateRequestId() {
    final id = _uuid.v4();
    return 'req_$id';
  }
}
