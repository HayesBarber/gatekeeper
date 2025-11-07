from pydantic import BaseModel


class GkKeyPair(BaseModel):
    instance_base_url: str


class GkKeyPairs(BaseModel):
    keypairs = list[GkKeyPair] = []
