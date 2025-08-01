from fastapi import APIRouter, HTTPException
from app.models.challenge_request import ChallengeRequest
from app.models.exceptions import ClientNotFound
from app.services import challenge_service

router = APIRouter(prefix="/challenge", tags=["Challenge"])

@router.post("/")
def generate_challenge(req: ChallengeRequest):
    try:
        return challenge_service.generate_challenge_response(req)
    except ClientNotFound as e:
        raise HTTPException(status_code=404, detail=str(e))
