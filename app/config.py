from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    required_headers: list[str] = []
    proxy_path: str = "/proxy"
    api_key_header: str = "x-api-key"
    client_id_header: str = "x-requestor-id"
    upstream_base_url: str = "http://localhost:8080"
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )

settings = Settings()
