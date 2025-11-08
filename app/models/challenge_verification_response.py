from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime


class ChallengeVerificationResponse(BaseModel):
    api_key: str = Field(..., description="Issued API key tied to this client")
    expires_at: datetime = Field(
        ..., description="UTC timestamp when this API key expires"
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "api_key": "dummy_key",
                "expires_at": "2025-08-31T23:59:59Z",
            }
        }
    )
