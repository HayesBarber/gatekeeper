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
    upstreams = {
        "/home-api": "http://localhost:8081",
        "/auth-api": "http://localhost:8082",
        "/metrics": "http://localhost:9090",
    }
    settings = Settings(upstreams=upstreams)
    redis_upstreams = settings.load_redis_upstreams()
    assert isinstance(redis_upstreams, dict)
    assert len(redis_upstreams) == 0
    upstreams = settings.upstreams
    assert len(upstreams) == 3
    combined = settings.get_combined_upstreams()
    assert len(combined) == 3
    assert combined == upstreams


def test_redis_upstream_overrides_static():
    static_path = "/static-path"
    static_upstream = "http://static-upstream"
    settings = Settings(
        upstreams={
            static_path: static_upstream,
            "/home-api": "http://localhost:8081",
            "/auth-api": "http://localhost:8082",
            "/metrics": "http://localhost:9090",
        }
    )
    assert len(settings.upstreams) == 4
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
    assert len(combined) == 4
    assert combined.get(static_path) == redis_upstream


def test_load_redis_upstreams_caches_for_30_seconds(monkeypatch):
    settings = Settings()
    path = "/cache-path"
    upstream1 = "http://upstream1"
    mapping1 = UpstreamMapping(prefix=path, base_url=upstream1)
    redis_client.set_model(Namespace.UPSTREAMS, path, mapping1)

    original_time = __import__("time").time()
    monkeypatch.setattr("time.time", lambda: original_time)

    # Load and cache
    redis_upstreams = settings.load_redis_upstreams()
    assert redis_upstreams.get(path) == upstream1

    # Change Redis value
    upstream2 = "http://upstream2"
    mapping2 = UpstreamMapping(prefix=path, base_url=upstream2)
    redis_client.set_model(Namespace.UPSTREAMS, path, mapping2)

    # time within 30 seconds: cache should still return old value
    monkeypatch.setattr("time.time", lambda: original_time + 10)
    cached_upstreams = settings.load_redis_upstreams()
    assert cached_upstreams.get(path) == upstream1


def test_cache_expires_after_30_seconds(monkeypatch):
    settings = Settings()
    path = "/cache-expire-path"
    upstream1 = "http://upstream1"
    mapping1 = UpstreamMapping(prefix=path, base_url=upstream1)
    redis_client.set_model(Namespace.UPSTREAMS, path, mapping1)

    original_time = __import__("time").time()
    monkeypatch.setattr("time.time", lambda: original_time)

    # Load and cache
    redis_upstreams = settings.load_redis_upstreams()
    assert redis_upstreams.get(path) == upstream1

    # Change Redis value
    upstream2 = "http://upstream2"
    mapping2 = UpstreamMapping(prefix=path, base_url=upstream2)
    redis_client.set_model(Namespace.UPSTREAMS, path, mapping2)

    # time after 31 seconds: cache expired, should load new value
    monkeypatch.setattr("time.time", lambda: original_time + 31)
    updated_upstreams = settings.load_redis_upstreams()
    assert updated_upstreams.get(path) == upstream2
