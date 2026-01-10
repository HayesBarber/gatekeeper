import '../exceptions/config_validation_exception.dart';

/// Utility class for parsing duration strings with unit support.
/// Supports: 30s, 5m, 2h, 1d, 45 (defaults to seconds)
class TtlParser {
  static Duration parse(String durationStr) {
    if (durationStr.trim().isEmpty) {
      throw ConfigValidationException('Duration cannot be empty');
    }

    final trimmed = durationStr.trim();

    // Match pattern: number followed by optional unit
    final regex = RegExp(r'^(\d+)([smhd])?$');
    final match = regex.firstMatch(trimmed);

    if (match == null) {
      throw ConfigValidationException(
        'Invalid duration format: "$durationStr". Expected format: number + optional unit (s, m, h, d)',
      );
    }

    final value = int.parse(match.group(1)!);
    final unit = match.group(2) ?? 's';

    if (value < 0) {
      throw ConfigValidationException('Duration cannot be negative: $value');
    }

    switch (unit) {
      case 's':
        return Duration(seconds: value);
      case 'm':
        return Duration(minutes: value);
      case 'h':
        return Duration(hours: value);
      case 'd':
        return Duration(days: value);
      default:
        throw ConfigValidationException(
          'Unsupported duration unit: $unit. Supported units: s, m, h, d',
        );
    }
  }
}
