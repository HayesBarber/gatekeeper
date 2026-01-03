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
    this.clientId,
  });
  final String method;
  final String path;
  final int timestamp;
  final String? subdomain;
  final String? userAgent;
  final String? clientIp;
  final int? contentLength;
  final String? clientId;

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'path': path,
      'timestamp': timestamp,
      if (subdomain != null) 'subdomain': subdomain,
      if (userAgent != null) 'user_agent': userAgent,
      if (clientIp != null) 'client_ip': clientIp,
      if (contentLength != null) 'content_length': contentLength,
      if (clientId != null) 'client_id': clientId,
    };
  }
}

class AuthenticationContext {
  AuthenticationContext({
    required this.apiKeyPresent,
    required this.apiKeyValid,
    required this.keyExpired,
    required this.pathBlacklisted,
    required this.authDurationMs,
  });
  final bool apiKeyPresent;
  final bool apiKeyValid;
  final bool keyExpired;
  final bool pathBlacklisted;
  final int authDurationMs;

  Map<String, dynamic> toJson() {
    return {
      'api_key_present': apiKeyPresent,
      'api_key_valid': apiKeyValid,
      'key_expired': keyExpired,
      'path_blacklisted': pathBlacklisted,
      'auth_duration_ms': authDurationMs,
    };
  }
}

class WebhookContext {
  WebhookContext({
    required this.signaturePresent,
    required this.signatureValid,
    required this.verificationDurationMs,
    this.eventType,
    this.deliveryId,
  });
  final bool signaturePresent;
  final bool signatureValid;
  final String? eventType;
  final String? deliveryId;
  final int verificationDurationMs;

  Map<String, dynamic> toJson() {
    return {
      'signature_present': signaturePresent,
      'signature_valid': signatureValid,
      if (eventType != null) 'event_type': eventType,
      if (deliveryId != null) 'delivery_id': deliveryId,
      'verification_duration_ms': verificationDurationMs,
    };
  }
}

class UpstreamContext {
  UpstreamContext({
    required this.forwarded,
    this.targetHost,
    this.forwardDurationMs,
  });
  final bool forwarded;
  final String? targetHost;
  final int? forwardDurationMs;

  Map<String, dynamic> toJson() {
    return {
      'forwarded': forwarded,
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
  const ResponseContext.unknown({
    this.statusCode = -1,
    this.durationMs = -1,
    this.contentLength = -1,
  });
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
    required this.operation,
    required this.operationDurationMs,
    this.challengeId,
    this.challengePresent,
    this.challengeExpired,
    this.signatureValid,
  });
  final String operation;
  final int operationDurationMs;
  final String? challengeId;
  final bool? challengePresent;
  final bool? challengeExpired;
  final bool? signatureValid;

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'operation_duration_ms': operationDurationMs,
      if (challengeId != null) 'challenge_id': challengeId,
      if (challengePresent != null) 'challenge_present': challengePresent,
      if (challengeExpired != null) 'challenge_expired': challengeExpired,
      if (signatureValid != null) 'signature_valid': signatureValid,
    };
  }
}
