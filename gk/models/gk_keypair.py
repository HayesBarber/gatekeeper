from pydantic import BaseModel


class GkKeyPair(BaseModel):
    instance_base_url: str
    public_key: bytes
    private_key: bytes


class GkKeyPairs(BaseModel):
    keypairs: list[GkKeyPair] = []
