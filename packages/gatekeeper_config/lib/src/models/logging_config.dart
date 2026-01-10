/// Configuration for logging settings.
class LoggingConfig {
  final bool enabled;

  LoggingConfig({required this.enabled});

  factory LoggingConfig.fromJson(Map<String, dynamic> json) {
    return LoggingConfig(enabled: json['enabled'] as bool);
  }

  Map<String, dynamic> toJson() {
    return {'enabled': enabled};
  }
}
