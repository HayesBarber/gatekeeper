from pydantic import BaseModel
from app.models import ChallengeVerificationResponse


class GkApiKey(BaseModel):
    instance_base_url: str
    api_key: ChallengeVerificationResponse


class GkApiKeys(BaseModel):
    api_keys: list[GkApiKey] = []
