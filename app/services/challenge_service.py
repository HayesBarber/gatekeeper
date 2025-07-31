from app.models.challenge_response import ChallengeResponse
from app.models.challenge_request import ChallengeRequest
from curveauth.challenge import generate_challenge
import secrets
from datetime import datetime, timedelta, timezone

def generate_challenge_response(req: ChallengeRequest, ttl_seconds: int = 300) -> ChallengeResponse:
   challenge_id = secrets.token_hex(16)
   challenge = generate_challenge()
   expires = datetime.now(timezone.utc) + timedelta(seconds=ttl_seconds)

   return ChallengeResponse(
      challenge_id=challenge_id,
      challenge=challenge,
      expires_at=expires
   )
