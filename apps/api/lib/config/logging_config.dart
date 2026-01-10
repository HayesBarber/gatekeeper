class LoggingConfig {
  const LoggingConfig({
    required this.loggingEnabled,
  });
  const LoggingConfig.defaultConfig() : loggingEnabled = true;

  final bool loggingEnabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoggingConfig &&
          runtimeType == other.runtimeType &&
          loggingEnabled == other.loggingEnabled;

  @override
  int get hashCode => loggingEnabled.hashCode;
}
