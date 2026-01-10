class WideEvent {
  WideEvent({
    required this.requestId,
    required this.request,
    this.response = const ResponseContext.unknown(),
    this.authentication,
    this.webhook,
    this.upstream,
    this.error,
    this.challenge,
  });
  final String requestId;
  final RequestContext request;
  ResponseContext response;
  AuthenticationContext? authentication;
  WebhookContext? webhook;
  UpstreamContext? upstream;
  ErrorContext? error;
  ChallengeContext? challenge;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'request_id': requestId,
      'request': request.toJson(),
      'response': response.toJson(),
      if (authentication != null) 'authentication': authentication!.toJson(),
      if (webhook != null) 'webhook': webhook!.toJson(),
      if (upstream != null) 'upstream': upstream!.toJson(),
      if (error != null) 'error': error!.toJson(),
      if (challenge != null) 'challenge': challenge!.toJson(),
    };

    return json;
  }
}

class RequestContext {
  RequestContext({
    required this.method,
    required this.path,
    required this.timestamp,
    this.subdomain,
    this.userAgent,
    this.clientIp,
    this.contentLength,
  });
  final String method;
  final String path;
  final int timestamp;
  final String? subdomain;
  final String? userAgent;
  final String? clientIp;
  final int? contentLength;

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'path': path,
      'timestamp': timestamp,
      if (subdomain != null) 'subdomain': subdomain,
      if (userAgent != null) 'user_agent': userAgent,
      if (clientIp != null) 'client_ip': clientIp,
      if (contentLength != null) 'content_length': contentLength,
    };
  }
}

class AuthenticationContext {
  AuthenticationContext({
    this.authTokenPresent,
    this.authTokenSource,
    this.authTokenStored,
    this.authTokenValid,
    this.keyExpired,
    this.pathBlacklisted,
    this.authDurationMs,
  });
  final bool? authTokenPresent;
  final String? authTokenSource;
  final bool? authTokenStored;
  final bool? authTokenValid;
  final bool? keyExpired;
  final bool? pathBlacklisted;
  final int? authDurationMs;

  Map<String, dynamic> toJson() {
    return {
      if (authTokenPresent != null) 'auth_token_present': authTokenPresent,
      if (authTokenSource != null) 'auth_token_source': authTokenSource,
      if (authTokenStored != null) 'auth_token_stored': authTokenStored,
      if (authTokenValid != null) 'auth_token_valid': authTokenValid,
      if (keyExpired != null) 'key_expired': keyExpired,
      if (pathBlacklisted != null) 'path_blacklisted': pathBlacklisted,
      if (authDurationMs != null) 'auth_duration_ms': authDurationMs,
    };
  }
}

class WebhookContext {
  WebhookContext({
    this.signaturePresent,
    this.signatureValid,
    this.verificationDurationMs,
    this.eventType,
    this.deliveryId,
  });
  final bool? signaturePresent;
  final bool? signatureValid;
  final int? verificationDurationMs;
  final String? eventType;
  final String? deliveryId;

  Map<String, dynamic> toJson() {
    return {
      if (signaturePresent != null) 'signature_present': signaturePresent,
      if (signatureValid != null) 'signature_valid': signatureValid,
      if (verificationDurationMs != null)
        'verification_duration_ms': verificationDurationMs,
      if (eventType != null) 'event_type': eventType,
      if (deliveryId != null) 'delivery_id': deliveryId,
    };
  }
}

class UpstreamContext {
  UpstreamContext({
    this.targetHost,
    this.forwardDurationMs,
  });
  final String? targetHost;
  final int? forwardDurationMs;

  Map<String, dynamic> toJson() {
    return {
      if (targetHost != null) 'target_host': targetHost,
      if (forwardDurationMs != null) 'forward_duration_ms': forwardDurationMs,
    };
  }
}

class ResponseContext {
  ResponseContext({
    required this.statusCode,
    required this.durationMs,
    this.contentLength,
  });
  const ResponseContext.unknown()
    : statusCode = -1,
      durationMs = -1,
      contentLength = -1;
  final int statusCode;
  final int durationMs;
  final int? contentLength;

  Map<String, dynamic> toJson() {
    return {
      'status_code': statusCode,
      'duration_ms': durationMs,
      if (contentLength != null) 'content_length': contentLength,
    };
  }
}

class ErrorContext {
  ErrorContext({
    required this.type,
    required this.code,
    required this.retriable,
    this.context,
  });
  final String type;
  final String code;
  final bool retriable;
  final Map<String, dynamic>? context;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'code': code,
      'retriable': retriable,
      if (context != null) 'context': context,
    };
  }
}

class ChallengeContext {
  ChallengeContext({
    this.operationDurationMs,
    this.publicKeyPresent,
    this.challengeId,
    this.challengePresent,
    this.challengeExpired,
    this.challengeIdMismatch,
    this.signatureValid,
  });
  final int? operationDurationMs;
  final bool? publicKeyPresent;
  final String? challengeId;
  final bool? challengePresent;
  final bool? challengeExpired;
  final bool? challengeIdMismatch;
  final bool? signatureValid;

  Map<String, dynamic> toJson() {
    return {
      if (operationDurationMs != null)
        'operation_duration_ms': operationDurationMs,
      if (publicKeyPresent != null) 'public_key_present': publicKeyPresent,
      if (challengeId != null) 'challenge_id': challengeId,
      if (challengePresent != null) 'challenge_present': challengePresent,
      if (challengeExpired != null) 'challenge_expired': challengeExpired,
      if (challengeIdMismatch != null)
        'challenge_id_mismatch': challengeIdMismatch,
      if (signatureValid != null) 'signature_valid': signatureValid,
    };
  }
}
