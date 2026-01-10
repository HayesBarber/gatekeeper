import '../exceptions/config_validation_exception.dart';

/// Utility class for validating URL paths for blacklist entries.
class PathValidator {
  static bool isValid(String path) {
    if (path.isEmpty) return false;
    if (!path.startsWith('/')) return false;
    if (path.endsWith('/') && path.length > 1)
      return false; // No trailing slash except for root
    if (path.contains('//')) return false; // No double slashes

    // Basic path validation - allow alphanumeric, hyphens, underscores, slashes, and wildcards
    final regex = RegExp(r'^/[a-zA-Z0-9\-_/\\*]*$');
    return regex.hasMatch(path);
  }

  static void validate(String path, String pathContext) {
    if (!isValid(path)) {
      throw ConfigValidationException(
        'Invalid path: "' +
            path +
            '". Must start with "/" and contain only valid path characters. Wildcards "*" and "**" are supported.',
        pathContext,
      );
    }
  }
}
