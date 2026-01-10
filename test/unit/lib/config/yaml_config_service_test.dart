import 'package:gatekeeper/config/logging_config.dart';
import 'package:gatekeeper/config/subdomain_config.dart';
import 'package:gatekeeper/config/yaml_config_service.dart';
import 'package:test/test.dart';

void main() {
  group('YamlConfigService', () {
    test('loads config from file', () async {
      const fullYaml = './test/unit/lib/config/test_yaml/full.yaml';
      final service = await YamlConfigService.load(path: fullYaml);
      final config = service.config;

      expect(config.redis.host, '192.168.1.10');
      expect(config.redis.challengesTtl, const Duration(seconds: 45));
      expect(config.redis.apiKeysTtl, const Duration(minutes: 10));
      expect(config.domain, 'test-domain.com');
      expect(
        config.logging,
        const LoggingConfig(
          loggingEnabled: true,
        ),
      );
      expect(config.subdomains, <String, SubdomainConfig>{
        'api': const SubdomainConfig(
          url: 'http://localhost:3000',
          blacklistedPaths: {
            'GET': ['/admin/*', '/health'],
            'POST': ['/users/delete'],
          },
        ),
        'webhook': const SubdomainConfig(url: 'http://localhost:4000'),
        'admin': const SubdomainConfig(
          url: 'http://localhost:5000',
          blacklistedPaths: {
            'GET': ['/config'],
            'POST': ['/shutdown'],
          },
        ),
        'github': const SubdomainConfig(
          url: 'http://localhost:6000',
          secret: 'test_secret',
        ),
      });
    });

    test('loads default app config on invalid path', () async {
      const invalidPath = './test/unit/lib/config/test_yaml/missing.yaml';
      final service = await YamlConfigService.load(path: invalidPath);
      final config = service.config;

      expect(config.redis.host, '127.0.0.1');
      expect(config.domain, isNull);
      expect(
        config.logging,
        const LoggingConfig(
          loggingEnabled: true,
        ),
      );
      expect(config.subdomains, <String, SubdomainConfig>{});
    });

    test('loads config partial yaml', () async {
      const partialYaml = './test/unit/lib/config/test_yaml/partial.yaml';
      final service = await YamlConfigService.load(path: partialYaml);
      final config = service.config;

      expect(config.redis.host, '127.0.0.1');
      expect(config.redis.challengesTtl, const Duration(hours: 2));
      expect(
        config.redis.apiKeysTtl,
        const Duration(minutes: 5),
      );
      expect(config.domain, isNull);
      expect(
        config.logging,
        const LoggingConfig(
          loggingEnabled: true,
        ),
      );
      expect(config.subdomains, <String, SubdomainConfig>{});
    });

    group('TTL Configuration Parsing', () {
      test('parses TTL with explicit units', () async {
        const ttlUnitsYaml =
            './test/unit/lib/config/test_yaml/ttl_explicit_units.yaml';
        final service = await YamlConfigService.load(path: ttlUnitsYaml);
        final config = service.config;

        expect(config.redis.challengesTtl, const Duration(seconds: 30));
        expect(config.redis.apiKeysTtl, const Duration(minutes: 5));
      });

      test('parses TTL with different time units', () async {
        const ttlDifferentUnitsYaml =
            './test/unit/lib/config/test_yaml/ttl_different_units.yaml';
        final service =
            await YamlConfigService.load(path: ttlDifferentUnitsYaml);
        final config = service.config;

        expect(config.redis.challengesTtl, const Duration(hours: 1));
        expect(config.redis.apiKeysTtl, const Duration(days: 2));
      });

      test('parses TTL with default seconds when no unit specified', () async {
        const ttlDefaultSecondsYaml =
            './test/unit/lib/config/test_yaml/ttl_default_seconds.yaml';
        final service =
            await YamlConfigService.load(path: ttlDefaultSecondsYaml);
        final config = service.config;

        expect(config.redis.challengesTtl, const Duration(seconds: 45));
        expect(config.redis.apiKeysTtl, const Duration(seconds: 120));
      });

      test('uses default TTL values when not specified', () async {
        const ttlNoSpecYaml =
            './test/unit/lib/config/test_yaml/ttl_no_spec.yaml';
        final service = await YamlConfigService.load(path: ttlNoSpecYaml);
        final config = service.config;

        expect(
          config.redis.challengesTtl,
          const Duration(seconds: 30),
        );
        expect(config.redis.apiKeysTtl, const Duration(minutes: 5));
      });

      test('handles partial TTL configuration with fallback', () async {
        const ttlPartialYaml =
            './test/unit/lib/config/test_yaml/ttl_partial.yaml';
        final service = await YamlConfigService.load(path: ttlPartialYaml);
        final config = service.config;

        expect(config.redis.challengesTtl, const Duration(minutes: 15));
        expect(
          config.redis.apiKeysTtl,
          const Duration(minutes: 5),
        );
      });

      test('handles whitespace in TTL values', () async {
        const ttlWhitespaceYaml =
            './test/unit/lib/config/test_yaml/ttl_whitespace.yaml';
        final service = await YamlConfigService.load(path: ttlWhitespaceYaml);
        final config = service.config;

        expect(config.redis.challengesTtl, const Duration(seconds: 40));
        expect(config.redis.apiKeysTtl, const Duration(minutes: 11));
      });

      test('falls back to defaults for invalid TTL formats', () async {
        const edgeCasesYaml =
            './test/unit/lib/config/test_yaml/ttl_edge_cases.yaml';
        final service = await YamlConfigService.load(path: edgeCasesYaml);
        final config = service.config;

        expect(config.redis.challengesTtl, const Duration(seconds: 15));

        expect(config.redis.apiKeysTtl, const Duration(minutes: 5));
      });

      test('handles empty TTL values', () async {
        const ttlEmptyYaml = './test/unit/lib/config/test_yaml/ttl_empty.yaml';
        final service = await YamlConfigService.load(path: ttlEmptyYaml);
        final config = service.config;

        expect(
          config.redis.challengesTtl,
          const Duration(seconds: 30),
        );
        expect(config.redis.apiKeysTtl, const Duration(minutes: 5));
      });
    });
  });
}
