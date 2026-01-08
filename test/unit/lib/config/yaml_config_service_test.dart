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

      expect(config.redisHost, '192.168.1.10');
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

      expect(config.redisHost, '127.0.0.1');
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

      expect(config.redisHost, '127.0.0.1');
      expect(config.domain, isNull);
      expect(
        config.logging,
        const LoggingConfig(
          loggingEnabled: true,
        ),
      );
      expect(config.subdomains, <String, SubdomainConfig>{});
    });
  });
}
