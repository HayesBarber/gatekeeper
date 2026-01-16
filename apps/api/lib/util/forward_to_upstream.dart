import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

class Forward {
  Future<Response> toUpstream(
    RequestContext context,
    Uri upstreamBase, {
    String? body,
  }) async {
    final client = HttpClient();
    try {
      final request = context.request;

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

      final requestBody = body ?? await request.body();
      if (requestBody.isNotEmpty) {
        upstreamReq.write(requestBody);
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
    } finally {
      client.close();
    }
  }

  static final _hopByHopHeaders = {
    'connection',
    'keep-alive',
    'proxy-authenticate',
    'proxy-authorization',
    'te',
    'trailer',
    'transfer-encoding',
    'upgrade',
  };
}
