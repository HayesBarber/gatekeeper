from pydantic import BaseModel, Field
from datetime import datetime

class ChallengeResponse(BaseModel):
    challenge_id: str = Field(..., description="Unique identifier for the challenge")
    challenge: str = Field(..., description="Challenge string to be signed by the client")
    expires_at: datetime = Field(..., description="UTC timestamp when the challenge expires")

    class Config:
        schema_extra = {
            "example": {
                "challenge_id": "83fcfcf6e2e84df7b7a84db6c52934f7",
                "challenge": "e9f34c6d9c0b4f74a1f9f3a2e5a1b3c4",
                "expires_at": "2025-07-31T23:59:59Z"
            }
        }
