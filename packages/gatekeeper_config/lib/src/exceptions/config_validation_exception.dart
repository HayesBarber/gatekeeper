class ConfigValidationException implements Exception {
  ConfigValidationException(this.message, [this.path]);

  final String message;
  final String? path;

  @override
  String toString() {
    if (path != null) {
      return 'ConfigValidationError: $message at $path';
    }
    return 'ConfigValidationError: $message';
  }
}
