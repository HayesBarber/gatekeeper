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
