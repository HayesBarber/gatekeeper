from app.models.challenge_response import ChallengeResponse
from app.models.challenge_request import ChallengeRequest
from app.models.challenge_verification_request import ChallengeVerificationRequest
from app.models.challenge_verification_response import ChallengeVerificationResponse
from curveauth.challenge import generate_challenge
from curveauth.api_keys import generate_api_key
import secrets
from datetime import datetime, timedelta, timezone
from app.utils.redis_client import redis_client, Namespace, get_ttl

def generate_challenge_response(req: ChallengeRequest) -> ChallengeResponse:
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

def generate_challenge_response(req: ChallengeVerificationRequest) -> ChallengeVerificationResponse:
   api_key = generate_api_key(prefix="api")
   ttl_seconds = get_ttl(Namespace.API_KEYS)
   expires = datetime.now(timezone.utc) + timedelta(seconds=ttl_seconds)

   return ChallengeVerificationResponse(
      api_key=api_key,
      expires_at=expires
   )
