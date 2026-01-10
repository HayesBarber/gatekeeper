import 'package:test/test.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  group('JsonConfigService', () {
    late Directory tempDir;
    late File configFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'gatekeeper_config_test_',
      );
      configFile = File('${tempDir.path}/config.json');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('reload', () {
      test('loads valid configuration successfully', () async {
        // Create test config
        final configData = {
          'redis': {
            'host': '127.0.0.1',
            'ttl': {'challenges': '30s', 'auth_tokens': '5m'},
          },
          'subdomains': {
            'api': {
              'url': 'http://localhost:3000',
              'blacklist': {
                'GET': ['/admin/*', '/health'],
                'POST': ['/users/delete'],
              },
            },
            'github': {
              'url': 'http://localhost:6000',
              'secret': 'github-webhook-secret',
            },
          },
          'logging': {'enabled': true},
          'domain': 'test-domain.com',
        };

        await configFile.writeAsString(jsonEncode(configData));

        // Test loading
        final service = JsonConfigService(configFile.path);
        await service.reload();

        final config = service.config;

        expect(config.redis.host, equals('127.0.0.1'));
        expect(config.redis.challengesTtl, equals(Duration(seconds: 30)));
        expect(config.redis.authTokensTtl, equals(Duration(minutes: 5)));

        expect(config.subdomains['api']?.url, equals('http://localhost:3000'));
        expect(
          config.subdomains['api']?.blacklistedPaths?['GET'],
          equals(['/admin/*', '/health']),
        );
        expect(
          config.subdomains['github']?.secret,
          equals('github-webhook-secret'),
        );

        expect(config.logging.enabled, isTrue);
        expect(config.domain, equals('test-domain.com'));
      });

      test('throws for missing file', () async {
        final service = JsonConfigService('non_existent_file.json');

        expect(
          () => service.reload(),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('throws for invalid JSON', () async {
        await configFile.writeAsString('invalid json content');

        final service = JsonConfigService(configFile.path);

        expect(
          () => service.reload(),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('throws for missing required fields', () async {
        final configData = {
          'redis': {'host': '127.0.0.1'},
          'subdomains': {},
          'logging': {'enabled': true},
        };

        await configFile.writeAsString(jsonEncode(configData));

        final service = JsonConfigService(configFile.path);

        expect(
          () => service.reload(),
          throwsA(isA<ConfigValidationException>()),
        );
      });
    });
  });
}
