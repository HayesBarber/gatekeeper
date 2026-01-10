typedef SignatureVerifier = bool Function(
  String message,
  String signature,
  String publicKey,
);
