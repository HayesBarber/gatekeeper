from pydantic import BaseModel, Field

class ChallengeVerificationRequest(BaseModel):
    challenge_id: str = Field(..., description="ID of the challenge to verify against")
    client_id: str = Field(..., min_length=3, max_length=64, description="ID of the client submitting the response")
    signature: str = Field(..., description="Base64-encoded signature over the challenge using client's private key")

    class Config:
        schema_extra = {
            "example": {
                "challenge_id": "83fcfcf6e2e84df7b7a84db6c52934f7",
                "client_id": "client_abc123",
                "signature": "MEUCIQDLnY..."
            }
        }
