from pydantic import BaseModel, Field

class ChallengeVerificationResponse(BaseModel):
    api_key: str = Field(..., description="Issued API key tied to this client")
    expires_at: str = Field(..., description="UTC timestamp when this API key expires")

    class Config:
        schema_extra = {
            "example": {
                "api_key": "sk_live_4f9e2c3b8f7a45c9a07cbd22f41c5ef7",
                "expires_at": "2025-08-31T23:59:59Z"
            }
        }
