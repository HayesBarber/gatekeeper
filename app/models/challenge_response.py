from pydantic import BaseModel, Field

class ChallengeResponse(BaseModel):
    challenge: str = Field(..., description="Random challenge string to be signed by the client")

    class Config:
        schema_extra = {
            "example": {
                "challenge": "e9f34c6d9c0b4f74a1f9f3a2e5a1b3c4"
            }
        }
