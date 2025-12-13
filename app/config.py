from pydantic_settings import (
    BaseSettings,
    PydanticBaseSettingsSource,
    SettingsConfigDict,
    YamlConfigSettingsSource,
)
from app.utils.logger import LOGGER
from app.utils.redis_client import Namespace, redis_client
from app.models.upstream import UpstreamMapping
import time


class Settings(BaseSettings):
    required_headers: dict[str, str | None] = {}
    proxy_path: str = "/proxy"
    api_key_header: str = "x-api-key"
    client_id_header: str = "x-requestor-id"
    upstreams: dict[str, str] = {}
    blacklisted_paths: dict[str, list[str]] = {}
    otel_enabled: bool = False
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        yaml_file="gatekeeper.yaml",
        yaml_file_encoding="utf-8",
        extra="ignore",
    )

    @classmethod
    def settings_customise_sources(
        cls,
        settings_cls: type[BaseSettings],
        init_settings: PydanticBaseSettingsSource,
        env_settings: PydanticBaseSettingsSource,
        dotenv_settings: PydanticBaseSettingsSource,
        file_secret_settings: PydanticBaseSettingsSource,
    ) -> tuple[PydanticBaseSettingsSource, ...]:
        return (
            init_settings,
            YamlConfigSettingsSource(settings_cls),
            env_settings,
            dotenv_settings,
            file_secret_settings,
        )

    def load_redis_upstreams(self) -> dict[str, str]:
        now = time.time()
        if hasattr(self, "_cached_upstreams") and hasattr(self, "_last_upstream_load"):
            if now - self._last_upstream_load < 30:
                return self._cached_upstreams
        upstreams = redis_client.get_all_models(Namespace.UPSTREAMS, UpstreamMapping)
        self._cached_upstreams = {m.prefix: m.base_url for m in upstreams.values()}
        self._last_upstream_load = now
        return self._cached_upstreams

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
