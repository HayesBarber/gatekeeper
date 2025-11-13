import pytest
from app.config import Settings
from app.utils.redis_client import redis_client, Namespace
from app.models import UpstreamMapping


@pytest.fixture(autouse=True)
def clean_redis():
    for ns in Namespace:
        pattern = f"{ns.value}:*"
        keys = redis_client._redis.keys(pattern)
        if keys:
            redis_client._redis.delete(*keys)


def test_load_redis_upstreams_returns_empty_when_no_data():
    settings = Settings()
    redis_upstreams = settings.load_redis_upstreams()
    assert isinstance(redis_upstreams, dict)
    assert len(redis_upstreams) == 0
    upstreams = settings.upstreams
    assert len(upstreams) == 0
    combined = settings.get_combined_upstreams()
    assert len(combined) == 0


def test_redis_upstream_overrides_static():
    static_path = "/static-path"
    static_upstream = "http://static-upstream"
    settings = Settings(
        upstreams={
            static_path: static_upstream,
        }
    )
    assert len(settings.upstreams) == 1
    assert settings.upstreams.get(static_path) == static_upstream

    redis_upstream = "http://redis-upstream"
    mapping = UpstreamMapping(
        prefix=static_path,
        base_url=redis_upstream,
    )
    redis_client.set_model(Namespace.UPSTREAMS, static_path, mapping)

    redis_upstreams = settings.load_redis_upstreams()
    assert redis_upstreams.get(static_path) == redis_upstream
    combined = settings.get_combined_upstreams()
    assert len(combined) == 1
    assert combined.get(static_path) == redis_upstream
