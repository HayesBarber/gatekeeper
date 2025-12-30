import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:gatekeeper/config/config_service.dart';
import 'package:gatekeeper/constants/headers.dart';
import 'package:gatekeeper/dto/challenge_verification_response.dart';
import 'package:gatekeeper/redis/redis_client.dart';
import 'package:gatekeeper/util/subdomain.dart';

Middleware subdomainGatekeeper() {
  return (handler) {
    return (context) async {
      final config = context.read<ConfigService>().config;
      final subdomain = Subdomain.fromUri(context.request.uri);
      final subdomainConfig = config.subdomains[subdomain];
      if (subdomain == null || subdomainConfig == null) {
        return handler(context);
      }

      final clientId = context.request.headers[headerRequestorId];
      if (clientId == null) {
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

      final apiKey = context.request.headers[headerApiKey];
      if (apiKey == null) {
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

      final redis = context.read<RedisClientBase>();
      final storedApiKeyData = await redis.get(
        ns: Namespace.apiKeys,
        key: clientId,
      );
      if (storedApiKeyData == null) {
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

      final storedApiKey = ChallengeVerificationResponse.decode(
        storedApiKeyData,
      );

      if (apiKey != storedApiKey.apiKey) {
        return Response(
          statusCode: HttpStatus.forbidden,
        );
      }

      final upstreamUrl = Uri.parse(subdomainConfig.url);

      return forwardToUpstream(
        context.request,
        upstreamUrl,
      );
    };
  };
}

Future<Response> forwardToUpstream(
  Request request,
  Uri upstreamBase,
) async {
  final client = HttpClient();

  final upstreamUri = upstreamBase.replace(
    path: request.uri.path,
    query: request.uri.query,
  );

  final upstreamReq = await client.openUrl(
    request.method.value,
    upstreamUri,
  );

  request.headers.forEach((key, value) {
    final lower = key.toLowerCase();
    if (_hopByHopHeaders.contains(lower)) return;
    if (lower == HttpHeaders.contentLengthHeader) return;

    upstreamReq.headers.set(key, value);
  });

  final body = await request.body();
  if (body.isNotEmpty) {
    upstreamReq.write(body);
  }

  final upstreamRes = await upstreamReq.close();

  final responseBytes = await upstreamRes.fold<List<int>>(
    <int>[],
    (acc, chunk) => acc..addAll(chunk),
  );

  final responseHeaders = <String, String>{};
  upstreamRes.headers.forEach((key, values) {
    final lower = key.toLowerCase();
    if (_hopByHopHeaders.contains(lower)) return;

    responseHeaders[key] = values.join(',');
  });

  return Response.bytes(
    body: responseBytes,
    statusCode: upstreamRes.statusCode,
    headers: responseHeaders,
  );
}

const _hopByHopHeaders = {
  'connection',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailer',
  'transfer-encoding',
  'upgrade',
};
