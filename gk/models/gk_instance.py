from pydantic import BaseModel


class GkInstance(BaseModel):
    base_url: str
    api_key_header: str = "x-api-key"
    client_id_header: str = "x-requestor-id"
    active: bool


class GkInstances(BaseModel):
    instances: list[GkInstance] = []
