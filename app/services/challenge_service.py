from app.models.challenge_response import ChallengeResponse
from app.models.challenge_request import ChallengeRequest
from app.models.challenge_verification_request import ChallengeVerificationRequest
from app.models.challenge_verification_response import ChallengeVerificationResponse
from curveauth.challenge import generate_challenge
from curveauth.api_keys import generate_api_key
import secrets
from datetime import datetime, timedelta, timezone

def generate_challenge_response(req: ChallengeRequest, ttl_seconds: int = 30) -> ChallengeResponse:
   challenge_id = secrets.token_hex(16)
   challenge = generate_challenge()
   expires = datetime.now(timezone.utc) + timedelta(seconds=ttl_seconds)

   return ChallengeResponse(
      challenge_id=challenge_id,
      challenge=challenge,
      expires_at=expires
   )

def generate_challenge_response(req: ChallengeVerificationRequest, ttl_seconds: int = 300) -> ChallengeVerificationResponse:
   api_key = generate_api_key(prefix="api")
   expires = datetime.now(timezone.utc) + timedelta(seconds=ttl_seconds)

   return ChallengeVerificationResponse(
      api_key=api_key,
      expires_at=expires
   )
