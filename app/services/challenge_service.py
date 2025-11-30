from app.models import (
    ChallengeResponse,
    ChallengeRequest,
    ChallengeVerificationRequest,
    ChallengeVerificationResponse,
    ClientNotFound,
    ChallengeNotVerified,
)
from curveauth.challenge import generate_challenge
from curveauth.api_keys import generate_api_key
from curveauth.signatures import verify_signature
import secrets
from datetime import datetime, timedelta, timezone
from app.utils.redis_client import redis_client, Namespace, get_ttl
from app.utils.otel import otel


def generate_challenge_response(req: ChallengeRequest) -> ChallengeResponse:
    if not redis_client.get(Namespace.USERS, req.client_id):
        otel.challenge_verification_failures.add(1, {"reason": "client_not_found"})
        raise ClientNotFound(req.client_id)

    challenge_id = secrets.token_hex(16)
    challenge = generate_challenge()
    ttl_seconds = get_ttl(Namespace.CHALLENGES) or 1

    expires = datetime.now(timezone.utc) + timedelta(seconds=ttl_seconds)

    response = ChallengeResponse(
        challenge_id=challenge_id,
        challenge=challenge,
        expires_at=expires,
    )

    redis_client.set_model(Namespace.CHALLENGES, req.client_id, response)
    otel.challenges_created.add(1, {"client_id": req.client_id})
    return response


def verify_challenge(
    req: ChallengeVerificationRequest,
) -> ChallengeVerificationResponse:
    otel.challenge_verification_attempts.add(1, {"client_id": req.client_id})

    stored = redis_client.get_model(
        Namespace.CHALLENGES, req.client_id, ChallengeResponse
    )
    if not stored:
        otel.challenge_verification_failures.add(1, {"reason": "client_not_found"})
        raise ClientNotFound(req.client_id)

    if stored.challenge_id != req.challenge_id:
        otel.challenge_verification_failures.add(1, {"reason": "challenge_id_mismatch"})
        raise ValueError("Challenge ID mismatch")

    if stored.expires_at < datetime.now(timezone.utc):
        otel.challenge_verification_failures.add(1, {"reason": "expired"})
        raise ValueError("Challenge has expired")

    public_key = redis_client.get(Namespace.USERS, req.client_id)
    if not public_key:
        otel.challenge_verification_failures.add(1, {"reason": "client_not_found"})
        raise ClientNotFound(req.client_id)

    verified = verify_signature(stored.challenge, req.signature, public_key, True)
    if not verified:
        otel.challenge_verification_failures.add(1, {"reason": "invalid_signature"})
        raise ChallengeNotVerified(req.client_id)

    api_key = generate_api_key(prefix="api")
    ttl_seconds = get_ttl(Namespace.API_KEYS) or 1

    expires = datetime.now(timezone.utc) + timedelta(seconds=ttl_seconds)

    response = ChallengeVerificationResponse(api_key=api_key, expires_at=expires)
    redis_client.set_model(Namespace.API_KEYS, req.client_id, response)
    redis_client.delete(Namespace.CHALLENGES, req.client_id)

    otel.api_keys_issued.add(1, {"client_id": req.client_id})
    return response
