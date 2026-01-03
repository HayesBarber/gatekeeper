import 'dart:convert';

import 'package:gatekeeper/logging/wide_event.dart';
import 'package:uuid/uuid.dart';

class Logger {
  factory Logger.init({
    required bool loggingEnabled,
  }) {
    _instance = Logger._(
      loggingEnabled: loggingEnabled,
    );
    return _instance!;
  }
  Logger._({
    required this.loggingEnabled,
  });

  static Logger? _instance;
  final bool loggingEnabled;
  final Uuid _uuid = const Uuid();

  static Logger instance() {
    if (_instance == null) {
      throw StateError('Logger not initialized. Call init() first.');
    }
    return _instance!;
  }

  void emitEvent(WideEvent event) {
    if (!loggingEnabled) {
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

  String generateRequestId() {
    final id = _uuid.v4();
    return 'req_$id';
  }
}
