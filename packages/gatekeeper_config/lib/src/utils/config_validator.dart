import '../exceptions/config_validation_exception.dart';
import 'ttl_parser.dart';
import 'subdomain_validator.dart';
import 'path_validator.dart';

/// Utility class for comprehensive JSON configuration validation.
class ConfigValidator {
  static const List<String> validHttpMethods = [
    'GET',
    'POST',
    'PUT',
    'DELETE',
    'PATCH',
    'HEAD',
    'OPTIONS',
    'TRACE',
  ];

  static void validateAppConfig(Map<String, dynamic> json) {
    // Validate required top-level fields
    _validateRequiredFields(json, [
      'redis',
      'subdomains',
      'logging',
      'domain',
    ], '\$');

    // Validate required domain field
    _validateDomainField(json);

    // Validate redis section
    _validateRedisSection(json['redis']);

    // Validate subdomains section
    _validateSubdomainsSection(json['subdomains']);

    // Validate logging section
    _validateLoggingSection(json['logging']);
  }

  static void _validateRequiredFields(
    Map<String, dynamic> json,
    List<String> requiredFields,
    String basePath,
  ) {
    for (final field in requiredFields) {
      if (!json.containsKey(field)) {
        throw ConfigValidationException(
          'Missing required field: ' + field,
          basePath + '.' + field,
        );
      }
    }
  }

  static void _validateRedisSection(Map<String, dynamic> redis) {
    final basePath = '\$.redis';

    // Validate required fields
    _validateRequiredFields(redis, ['host', 'ttl'], basePath);

    // Validate host
    if (redis['host'] is! String || (redis['host'] as String).isEmpty) {
      throw ConfigValidationException(
        'redis.host must be a non-empty string',
        basePath + '.host',
      );
    }

    // Validate URL format for host
    try {
      Uri.parse(redis['host'] as String);
    } catch (e) {
      throw ConfigValidationException(
        'redis.host must be a valid URL: "' + redis['host'].toString() + '"',
        basePath + '.host',
      );
    }

    // Validate TTL section
    final ttl = redis['ttl'];
    if (ttl is! Map<String, dynamic>) {
      throw ConfigValidationException(
        'redis.ttl must be an object',
        basePath + '.ttl',
      );
    }

    _validateTtlSection(ttl, basePath + '.ttl');
  }

  static void _validateTtlSection(Map<String, dynamic> ttl, String basePath) {
    _validateRequiredFields(ttl, ['challenges', 'auth_tokens'], basePath);

    // Validate challenges TTL
    _validateDurationField(ttl['challenges'], basePath + '.challenges');

    // Validate auth_tokens TTL
    _validateDurationField(ttl['auth_tokens'], basePath + '.auth_tokens');
  }

  static void _validateDurationField(dynamic value, String path) {
    if (value is! String) {
      throw ConfigValidationException('Duration must be a string', path);
    }

    try {
      TtlParser.parse(value);
    } catch (e) {
      throw ConfigValidationException(e.toString(), path);
    }
  }

  static void _validateSubdomainsSection(Map<String, dynamic> subdomains) {
    final basePath = '\$.subdomains';

    if (subdomains.isEmpty) {
      throw ConfigValidationException(
        'subdomains section cannot be empty',
        basePath,
      );
    }

    for (final entry in subdomains.entries) {
      final subdomainName = entry.key;
      final subdomainConfig = entry.value;

      // Validate subdomain name
      SubdomainValidator.validate(
        subdomainName,
        basePath + '["' + subdomainName + '"]',
      );

      if (subdomainConfig is! Map<String, dynamic>) {
        throw ConfigValidationException(
          'Subdomain configuration must be an object',
          basePath + '["' + subdomainName + '"]',
        );
      }

      _validateSubdomainConfig(
        subdomainConfig,
        basePath + '["' + subdomainName + '"]',
      );
    }
  }

  static void _validateSubdomainConfig(
    Map<String, dynamic> config,
    String basePath,
  ) {
    _validateRequiredFields(config, ['url'], basePath);

    // Validate URL
    if (config['url'] is! String || config['url'].isEmpty) {
      throw ConfigValidationException(
        'url must be a non-empty string',
        basePath + '.url',
      );
    }

    try {
      Uri.parse(config['url'] as String);
    } catch (e) {
      throw ConfigValidationException(
        'url must be a valid URL: "' + config['url'] + '"',
        basePath + '.url',
      );
    }

    // Validate optional blacklist
    if (config.containsKey('blacklist')) {
      final blacklist = config['blacklist'];
      if (blacklist is! Map<String, dynamic>) {
        throw ConfigValidationException(
          'blacklist must be an object',
          basePath + '.blacklist',
        );
      }

      _validateBlacklist(blacklist, basePath + '.blacklist');
    }

    // Validate optional secret
    if (config.containsKey('secret')) {
      final secret = config['secret'];
      if (secret is! String) {
        throw ConfigValidationException(
          'secret must be a string',
          basePath + '.secret',
        );
      }
    }
  }

  static void _validateBlacklist(
    Map<String, dynamic> blacklist,
    String basePath,
  ) {
    for (final entry in blacklist.entries) {
      final method = entry.key;
      final paths = entry.value;

      // Validate HTTP method
      if (!validHttpMethods.contains(method)) {
        throw ConfigValidationException(
          'Invalid HTTP method: "' +
              method +
              '". Valid methods: ' +
              validHttpMethods.join(', '),
          basePath + '.' + method,
        );
      }

      if (paths is! List<dynamic>) {
        throw ConfigValidationException(
          'Blacklist paths must be an array',
          basePath + '.' + method,
        );
      }

      final pathsList = paths;
      for (var i = 0; i < pathsList.length; i++) {
        final path = pathsList[i];
        if (path is! String) {
          throw ConfigValidationException(
            'Blacklist path must be a string',
            basePath + '.' + method + '[' + i.toString() + ']',
          );
        }

        PathValidator.validate(
          path,
          basePath + '.' + method + '[' + i.toString() + ']',
        );
      }
    }
  }

  static void _validateLoggingSection(Map<String, dynamic> logging) {
    final basePath = '\$.logging';

    _validateRequiredFields(logging, ['enabled'], basePath);

    // Validate enabled field
    if (logging['enabled'] is! bool) {
      throw ConfigValidationException(
        'logging.enabled must be a boolean',
        basePath + '.enabled',
      );
    }
  }

  static void _validateDomainField(Map<String, dynamic> json) {
    final domain = json['domain'];
    if (domain == null || domain.isEmpty) {
      throw ConfigValidationException(
        'domain must be a non-empty string',
        '\$.domain',
      );
    }
  }
}
