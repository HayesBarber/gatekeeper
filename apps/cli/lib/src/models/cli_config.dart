/// CLI configuration data model for Gatekeeper CLI.
class CliConfig {
  CliConfig({
    required this.cli,
    required this.gatekeeper,
    required this.auth,
    required this.defaults,
  });

  factory CliConfig.fromJson(Map<String, dynamic> json) {
    return CliConfig(
      cli: CliInfo.fromJson(json['cli'] as Map<String, dynamic>),
      gatekeeper: GatekeeperConfig.fromJson(
        json['gatekeeper'] as Map<String, dynamic>,
      ),
      auth: AuthConfig.fromJson(json['auth'] as Map<String, dynamic>),
      defaults: DefaultsConfig.fromJson(
        json['defaults'] as Map<String, dynamic>,
      ),
    );
  }

  final CliInfo cli;
  final GatekeeperConfig gatekeeper;
  final AuthConfig auth;
  final DefaultsConfig defaults;

  Map<String, dynamic> toJson() {
    return {
      'cli': cli.toJson(),
      'gatekeeper': gatekeeper.toJson(),
      'auth': auth.toJson(),
      'defaults': defaults.toJson(),
    };
  }
}

class CliInfo {
  CliInfo({
    required this.version,
    required this.initializedAt,
    required this.gatekeeperConfigPath,
  });

  factory CliInfo.fromJson(Map<String, dynamic> json) {
    return CliInfo(
      version: json['version'] as String,
      initializedAt: json['initialized_at'] as String,
      gatekeeperConfigPath: json['gatekeeper_config_path'] as String,
    );
  }

  final String version;
  final String initializedAt;
  final String gatekeeperConfigPath;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'initialized_at': initializedAt,
      'gatekeeper_config_path': gatekeeperConfigPath,
    };
  }
}

class GatekeeperConfig {
  GatekeeperConfig({
    required this.domain,
    required this.subdomains,
  });

  factory GatekeeperConfig.fromJson(Map<String, dynamic> json) {
    final subdomainsJson = json['subdomains'] as Map<String, dynamic>;
    final subdomains = <String, SubdomainInfo>{};

    for (final entry in subdomainsJson.entries) {
      subdomains[entry.key] = SubdomainInfo.fromJson(
        entry.value as Map<String, dynamic>,
      );
    }

    return GatekeeperConfig(
      domain: json['domain'] as String,
      subdomains: subdomains,
    );
  }

  final String domain;
  final Map<String, SubdomainInfo> subdomains;

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      'subdomains': subdomains.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }
}

class SubdomainInfo {
  SubdomainInfo({
    required this.url,
    required this.upstream,
  });

  factory SubdomainInfo.fromJson(Map<String, dynamic> json) {
    return SubdomainInfo(
      url: json['url'] as String,
      upstream: json['upstream'] as String,
    );
  }

  final String url;
  final String upstream;

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'upstream': upstream,
    };
  }
}

class AuthConfig {
  AuthConfig({
    required this.keypairPath,
    required this.generatedAt,
    required this.deviceId,
  });

  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    return AuthConfig(
      keypairPath: json['keypair_path'] as String,
      generatedAt: json['generated_at'] as String,
      deviceId: json['device_id'] as String,
    );
  }

  final String keypairPath;
  final String generatedAt;
  final String deviceId;

  Map<String, dynamic> toJson() {
    return {
      'keypair_path': keypairPath,
      'generated_at': generatedAt,
      'device_id': deviceId,
    };
  }
}

class DefaultsConfig {
  DefaultsConfig({
    required this.outputFormat,
  });

  factory DefaultsConfig.fromJson(Map<String, dynamic> json) {
    return DefaultsConfig(
      outputFormat: json['output_format'] as String,
    );
  }

  final String outputFormat;

  Map<String, dynamic> toJson() {
    return {
      'output_format': outputFormat,
    };
  }
}
