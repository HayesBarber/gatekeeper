from pydantic_settings import BaseSettings, SettingsConfigDict
from app.utils.logger import LOGGER
from app.utils.redis_client import Namespace, redis_client
from app.models.upstream import UpstreamMapping


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
        extra="ignore",
    )

    def load_redis_upstreams(self) -> dict[str, str]:
        upstreams = redis_client.get_all_models(Namespace.UPSTREAMS, UpstreamMapping)
        return {m.prefix: m.base_url for m in upstreams.values()}

    def get_combined_upstreams(self) -> dict[str, str]:
        redis_upstreams = self.load_redis_upstreams()
        combined = {**self.upstreams, **redis_upstreams}
        return combined

    def get_upstream_for_path(self, path: str) -> tuple[str, str] | None:
        """
        Return (matched_prefix, upstream_base_url) using longest-prefix match.
        `path` is the portion after the proxy_path (may start with '/').
        """
        if not path:
            path = "/"
        if not path.startswith("/"):
            path = "/" + path

        combined_upstreams = self.get_combined_upstreams()
        matches = [(p, u) for p, u in combined_upstreams.items() if path.startswith(p)]
        if not matches:
            return None
        prefix, url = max(matches, key=lambda x: len(x[0]))
        return prefix, url

    def resolve_upstream(self, path: str) -> tuple[str, str] | None:
        """
        Return (base_url, trimmed_path) where trimmed_path has the matched prefix removed.
        Example:
          path="/home-api/health", match prefix="/home-api" -> returns ("http://...:8081", "/health")
        """
        if not path:
            path = "/"
        if not path.startswith("/"):
            path = "/" + path
        match = self.get_upstream_for_path(path)
        if not match:
            return None

        prefix, base = match

        if prefix:
            trimmed = path[len(prefix) :]
            if not trimmed:
                trimmed = "/"
            elif not trimmed.startswith("/"):
                trimmed = "/" + trimmed
        else:
            trimmed = path
        return base, trimmed


settings = Settings()

LOGGER.info(f"Loaded settings: {settings.model_dump_json()}")
