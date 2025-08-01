from fastapi import APIRouter
from app.controllers.challenge_controller import router as challenge_router

api_router = APIRouter()
api_router.include_router(challenge_router)
