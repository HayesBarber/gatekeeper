import 'package:gatekeeper/config/yaml_config_service.dart';
import 'package:test/test.dart';

void main() {
  group('YamlConfigService', () {
    test('loads config from file', () async {
      const fullYaml = './test/unit/lib/config/test_yaml/full.yaml';
      final service = await YamlConfigService.load(path: fullYaml);
      final config = service.config;

      expect(config.redisHost, '192.168.1.10');
      expect(config.clientIdHeader, 'x-client-id');
      expect(config.subdomainUpstreams, <String, String>{
        'api': 'http://localhost:3000',
        'webhook': 'http://localhost:4000',
        'admin': 'http://localhost:5000',
      });
    });

    test('loads default app config on invalid path', () async {
      const invalidPath = './test/unit/lib/config/test_yaml/missing.yaml';
      final service = await YamlConfigService.load(path: invalidPath);
      final config = service.config;

      expect(config.redisHost, '127.0.0.1');
      expect(config.clientIdHeader, 'x-requestor-id');
      expect(config.subdomainUpstreams, <String, String>{});
    });

    test('loads config partial yaml', () async {
      const partialYaml = './test/unit/lib/config/test_yaml/partial.yaml';
      final service = await YamlConfigService.load(path: partialYaml);
      final config = service.config;

      expect(config.redisHost, '127.0.0.1');
      expect(config.clientIdHeader, 'x-custom-id');
      expect(config.subdomainUpstreams, <String, String>{});
    });
  });
}
