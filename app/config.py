from pydantic_settings import BaseSettings, SettingsConfigDict
from app.utils.logger import LOGGER

class Settings(BaseSettings):
    required_headers: dict[str, str | None] = {}
    proxy_path: str = "/proxy"
    api_key_header: str = "x-api-key"
    client_id_header: str = "x-requestor-id"
    upstream_base_url: str = "http://localhost:8080"
    blacklisted_paths: dict[str, list[str]] = {}
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )

settings = Settings()

LOGGER.info(f"Loaded settings: {settings.model_dump_json()}")
