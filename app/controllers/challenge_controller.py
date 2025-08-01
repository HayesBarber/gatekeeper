from fastapi import APIRouter
from app.models.challenge_request import ChallengeRequest
from app.services import challenge_service

router = APIRouter(prefix="/challenge", tags=["Challenge"])

@router.post("/")
def generate_challenge(req: ChallengeRequest):
    return challenge_service.generate_challenge_response(req)
