import '../exceptions/config_validation_exception.dart';

/// Utility class for validating subdomain names according to RFC 1035 DNS naming conventions.
class SubdomainValidator {
  static bool isValid(String subdomain) {
    if (subdomain.isEmpty) return false;
    if (subdomain.length > 63) return false;

    // RFC 1035 with case sensitivity: [a-z]([a-z0-9-]{0,61}[a-z0-9])?
    final regex = RegExp(r'^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$');
    return regex.hasMatch(subdomain);
  }

  static void validate(String subdomain, String path) {
    if (!isValid(subdomain)) {
      throw ConfigValidationException(
        'Invalid subdomain name: "' +
            subdomain +
            '". Must be 1-63 characters, contain only lowercase letters, numbers, and hyphens, cannot start or end with a hyphen.',
        path,
      );
    }
  }
}
