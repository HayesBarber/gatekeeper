import os
import redis
from enum import Enum
from typing import Optional, Any, Type, TypeVar, Dict, Tuple, Iterator, List
from pydantic import BaseModel, ValidationError
from app.utils.logger import LOGGER

T = TypeVar("T", bound=BaseModel)

class Namespace(str, Enum):
    CHALLENGES = "challenges"
    API_KEYS = "api_keys"
    USERS = "users"

class TTL(int, Enum):
    API_KEYS = 5 * 60
    CHALLENGES = 30

def _make_key(namespace: Namespace, key: str) -> str:
    return f"{namespace.value}:{key.strip()}"

def get_ttl(ns: Namespace) -> Optional[int]:
    return TTL[ns.name].value if ns.name in TTL.__members__ else None

class RedisClient:
    def __init__(self, redis_url: Optional[str] = None):
        redis_url = redis_url or os.getenv("REDIS_URL", "redis://localhost:6379")
        self._redis = redis.from_url(redis_url)

    def get(self, namespace: Namespace, key: str) -> Optional[str]:
        value = self._redis.get(_make_key(namespace, key))
        return value.decode("utf-8") if value else None

    def set(self, namespace: Namespace, key: str, value: Any):
        val = value if isinstance(value, (str, bytes)) else str(value)
        val = val.strip()
        self._redis.set(_make_key(namespace, key), val, ex=get_ttl(namespace))

    def delete(self, namespace: Namespace, key: str):
        self._redis.delete(_make_key(namespace, key))

    def get_model(self, namespace: Namespace, key: str, model: Type[T]) -> Optional[T]:
        raw = self.get(namespace, key)
        if not raw:
            return None
        try:
            return model.model_validate_json(raw)
        except ValidationError:
            raise RuntimeError(f"Invalid model JSON for key: {_make_key(namespace, key)}")

    def set_model(self, namespace: Namespace, key: str, model_instance: BaseModel):
        self.set(namespace, key, model_instance.model_dump_json())

    def _get_all_raw(self, namespace: Namespace) -> Iterator[Tuple[str, bytes]]:
        pattern = f"{namespace.value}:*"
        keys = self._redis.keys(pattern)
        if not keys:
            return
        values = self._redis.mget(keys)
        for full_key, value in zip(keys, values):
            if value is not None:
                orig_key = full_key.decode().split(":", 1)[1]
                yield orig_key, value

    def get_all(self, namespace: Namespace) -> Dict[str, str]:
        return {
            key: val.decode("utf-8")
            for key, val in self._get_all_raw(namespace)
        }

    def get_all_models(self, namespace: Namespace, model: Type[T]) -> Dict[str, T]:
        models = {}
        for key, val in self._get_all_raw(namespace):
            try:
                models[key] = model.model_validate_json(val)
            except ValidationError:
                LOGGER.error(f"[Redis] Skipping invalid model for key: {_make_key(namespace, key)}")
            except Exception as e:
                LOGGER.error(f"[Redis] Unexpected error on key {_make_key(namespace, key)}: {e}")
        return models

    def set_all_models(self, namespace: Namespace, model_list: List[T], key_field: str) -> int:
        if not model_list:
            return 0

        try:
            data = {
                _make_key(namespace, str(getattr(model, key_field))): model.model_dump_json()
                for model in model_list
            }
        except AttributeError as e:
            raise AttributeError(f"[Redis] key_field '{key_field}' not found on model.") from e

        pipe = self._redis.pipeline()
        ttl = get_ttl(namespace)
        for key, val in data.items():
            pipe.set(key, val)
            if ttl:
                pipe.expire(key, ttl)
        pipe.execute()

        return len(data)

redis_client = RedisClient()
