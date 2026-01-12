import 'package:gatekeeper_cli/src/models/cli_config.dart';
import 'package:gatekeeper_cli/src/version.dart';
import 'package:gatekeeper_config/gatekeeper_config.dart';

/// Maps Gatekeeper configuration to CLI configuration.
class ConfigMapper {
  static CliConfig mapToCliConfig(
    AppConfig appConfig,
    String configPath,
    String generatedAt,
    String deviceId,
  ) {
    final cliInfo = CliInfo(
      version: packageVersion,
      initializedAt: generatedAt,
      gatekeeperConfigPath: configPath,
    );

    final gatekeeperConfig = GatekeeperConfig(
      domain: appConfig.domain,
      subdomains: _mapSubdomains(appConfig),
    );

    final authConfig = AuthConfig(
      keypairPath: '~/.gatekeeper/keypair.json',
      generatedAt: generatedAt,
      deviceId: deviceId,
    );

    return CliConfig(
      cli: cliInfo,
      gatekeeper: gatekeeperConfig,
      auth: authConfig,
    );
  }

  static Map<String, SubdomainInfo> _mapSubdomains(AppConfig appConfig) {
    final subdomains = <String, SubdomainInfo>{};

    for (final entry in appConfig.subdomains.entries) {
      final subdomainName = entry.key;
      final subdomainConfig = entry.value;

      final httpsUrl = 'https://$subdomainName.${appConfig.domain}';

      subdomains[subdomainName] = SubdomainInfo(
        url: httpsUrl,
        upstream: subdomainConfig.url,
      );
    }

    return subdomains;
  }
}
