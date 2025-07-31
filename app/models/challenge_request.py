from pydantic import BaseModel, Field

class ChallengeRequest(BaseModel):
    client_id: str = Field(..., min_length=3, max_length=64, description="Unique identifier for the requesting client")

    class Config:
        schema_extra = {
            "example": {
                "client_id": "client_abc123",
            }
        }
