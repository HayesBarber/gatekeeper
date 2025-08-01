from app.models.challenge_response import ChallengeResponse
from app.models.challenge_request import ChallengeRequest
from app.models.challenge_verification_request import ChallengeVerificationRequest
from app.models.challenge_verification_response import ChallengeVerificationResponse
from app.models.exceptions import ClientNotFound, ChallengeNotVerified
from curveauth.challenge import generate_challenge
from curveauth.api_keys import generate_api_key
from curveauth.signatures import verify_signature
import secrets
from datetime import datetime, timedelta, timezone
from app.utils.redis_client import redis_client, Namespace, get_ttl

def generate_challenge_response(req: ChallengeRequest) -> ChallengeResponse:
   if not redis_client.get(Namespace.USERS, req.client_id):
      raise ClientNotFound(req.client_id)

   challenge_id = secrets.token_hex(16)
   challenge = generate_challenge()
   ttl_seconds = get_ttl(Namespace.CHALLENGES)
   expires = datetime.now(timezone.utc) + timedelta(seconds=ttl_seconds)

   response = ChallengeResponse(
      challenge_id=challenge_id,
      challenge=challenge,
      expires_at=expires
   )

   redis_client.set_model(Namespace.CHALLENGES, req.client_id, response)

   return response

def verify_challenge_response(req: ChallengeVerificationRequest) -> ChallengeVerificationResponse:
   stored = redis_client.get_model(Namespace.CHALLENGES, req.client_id, ChallengeResponse)
   if not stored:
      raise ClientNotFound(req.client_id)
   if stored.challenge_id != req.challenge_id:
      raise ValueError("Challenge ID mismatch")
   if stored.expires_at < datetime.now(timezone.utc):
      raise ValueError("Challenge has expired")
   
   public_key = redis_client.get(Namespace.USERS, req.client_id)
   if not public_key:
      raise ClientNotFound(req.client_id)
   
   verified = verify_signature(stored.challenge, req.signature, public_key, True)
   if not verified:
      raise ChallengeNotVerified(req.client_id)

   api_key = generate_api_key(prefix="api")
   ttl_seconds = get_ttl(Namespace.API_KEYS)
   expires = datetime.now(timezone.utc) + timedelta(seconds=ttl_seconds)

   response = ChallengeVerificationResponse(
      api_key=api_key,
      expires_at=expires
   )

   return response
