from pydantic import BaseModel


class GkInstance(BaseModel):
    base_url: str
    proxy_path: str = "/proxy"
    client_id: str
    api_key_header: str = "x-api-key"
    client_id_header: str = "x-requestor-id"
    active: bool
    public_key: str = ""
    other_headers: dict[str, str] = {}


class GkInstances(BaseModel):
    instances: list[GkInstance] = []
