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

    print(event.toJson());
  }

  String generateRequestId() {
    final id = _uuid.v4();
    return 'req_$id';
  }
}
