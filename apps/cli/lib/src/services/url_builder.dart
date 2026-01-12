import 'package:gatekeeper_cli/src/constants/protocols.dart';
import 'package:mason_logger/mason_logger.dart';

class UrlBuilder {
  UrlBuilder();

  String buildBaseUrl(
    String domain, {
    bool useHttps = true,
    Logger? logger,
  }) {
    final protocol = useHttps ? Protocols.https : Protocols.http;
    final url = '$protocol://$domain';

    if (!useHttps && logger != null) {
      logger
        ..warn('Using HTTP protocol - insecure for development only')
        ..detail('API endpoint: $url');
    }

    return url;
  }
}
