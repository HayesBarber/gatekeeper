class LoggingConfig {
  const LoggingConfig({
    required this.loggingEnabled,
    required this.slowRequestThresholdMs,
    required this.successfulSampleRate,
  });
  const LoggingConfig.defaultConfig()
      : loggingEnabled = true,
        slowRequestThresholdMs = 1000,
        successfulSampleRate = 0.1;

  final bool loggingEnabled;
  final int slowRequestThresholdMs;
  final double successfulSampleRate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoggingConfig &&
          runtimeType == other.runtimeType &&
          loggingEnabled == other.loggingEnabled &&
          slowRequestThresholdMs == other.slowRequestThresholdMs &&
          successfulSampleRate == other.successfulSampleRate;

  @override
  int get hashCode =>
      loggingEnabled.hashCode ^
      slowRequestThresholdMs.hashCode ^
      successfulSampleRate.hashCode;
}
