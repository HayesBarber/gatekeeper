from pydantic import BaseModel, Field, ConfigDict


class ChallengeRequest(BaseModel):
    client_id: str = Field(
        ..., min_length=3, max_length=64, description="ID of the requesting client"
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "client_id": "client_abc123",
            }
        }
    )
