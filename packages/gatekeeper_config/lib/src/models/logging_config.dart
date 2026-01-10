/// Configuration for logging settings.
class LoggingConfig {
  LoggingConfig({required this.enabled});

  factory LoggingConfig.fromJson(Map<String, dynamic> json) {
    return LoggingConfig(enabled: json['enabled'] as bool);
  }

  final bool enabled;

  Map<String, dynamic> toJson() {
    return {'enabled': enabled};
  }
}
