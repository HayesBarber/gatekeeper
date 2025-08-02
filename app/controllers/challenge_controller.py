from fastapi import APIRouter, HTTPException
from app.models import ChallengeRequest, ChallengeVerificationRequest, ChallengeVerificationResponse, ClientNotFound, ChallengeNotVerified
from app.services import challenge_service

router = APIRouter(prefix="/challenge", tags=["Challenge"])

@router.post("/")
def generate_challenge(req: ChallengeRequest):
    try:
        return challenge_service.generate_challenge_response(req)
    except ClientNotFound as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.post("/verify", response_model=ChallengeVerificationResponse)
def verify_challenge(req: ChallengeVerificationRequest):
    try:
        return challenge_service.verify_challenge(req)
    except ClientNotFound as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ChallengeNotVerified as e:
        raise HTTPException(status_code=403, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
