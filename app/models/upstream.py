from pydantic import BaseModel


class UpstreamMapping(BaseModel):
    prefix: str
    base_url: str
