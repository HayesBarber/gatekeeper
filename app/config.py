from pydantic_settings import BaseSettings, SettingsConfigDict
from app.utils.logger import LOGGER


class Settings(BaseSettings):
    required_headers: dict[str, str | None] = {}
    proxy_path: str = "/proxy"
    api_key_header: str = "x-api-key"
    client_id_header: str = "x-requestor-id"
    upstreams: dict[str, str] = {"": "http://localhost:8080"}
    blacklisted_paths: dict[str, list[str]] = {}
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )

    def get_upstream_for_path(self, path: str) -> str | None:
        """
        Return the upstream base URL that best matches `path` using
        longest-prefix match. `path` is expected to be the portion
        after the proxy_path (may start with '/').
        """
        if not path.startswith("/"):
            path = "/" + path
        matches = [(p, u) for p, u in self.upstreams.items() if path.startswith(p)]
        if not matches:
            return None
        prefix, url = max(matches, key=lambda x: len(x[0]))
        return url


settings = Settings()

LOGGER.info(f"Loaded settings: {settings.model_dump_json()}")
