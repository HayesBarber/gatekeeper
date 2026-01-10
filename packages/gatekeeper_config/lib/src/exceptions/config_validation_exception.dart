class ConfigValidationException implements Exception {
  final String message;
  final String? path;

  ConfigValidationException(this.message, [this.path]);

  @override
  String toString() {
    if (path != null) {
      return 'ConfigValidationError: $message at $path';
    }
    return 'ConfigValidationError: $message';
  }
}
