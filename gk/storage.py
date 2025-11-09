from pathlib import Path
from enum import Enum
from typing import Type, Dict
from pydantic import BaseModel
from gk.models.gk_instance import GkInstances, GkInstance
from gk.models.gk_keypair import GkKeyPairs, GkKeyPair
from gk.models.gk_apikey import GkApiKeys, GkApiKey
import os

DATA_DIR = Path.home() / ".gk"


class StorageKey(str, Enum):
    INSTANCES = "instances"
    KEYPAIRS = "keypairs"
    APIKEYS = "apikeys"


FILE_NAMES: dict[StorageKey, str] = {
    StorageKey.INSTANCES: "instances.json",
    # todo these should be stored securely
    StorageKey.KEYPAIRS: "keypairs.json",
    StorageKey.APIKEYS: "apikeys.json",
}


def ensure_data_dir():
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    os.chmod(DATA_DIR, 0o700)


def path_for(key: StorageKey) -> Path:
    return DATA_DIR / FILE_NAMES[key]


MODEL_FOR_KEY: Dict[StorageKey, Type[BaseModel]] = {
    StorageKey.INSTANCES: GkInstances,
    StorageKey.KEYPAIRS: GkKeyPairs,
    StorageKey.APIKEYS: GkApiKeys,
}


def load_model(key: StorageKey) -> BaseModel:
    """
    Load and validate JSON file into the associated Pydantic model.
    If file is missing returns an empty/default model instance.
    """
    file_path = path_for(key)
    model_cls = MODEL_FOR_KEY[key]
    if not file_path.exists():
        return model_cls()
    text = file_path.read_text()
    return model_cls.model_validate_json(text)


def save_model(key: StorageKey, model: BaseModel):
    """
    Save a Pydantic model to the file corresponding to key.
    """
    file_path = path_for(key)
    with open(file_path, "w") as f:
        f.write(model.model_dump_json(indent=2))


def persist_model_item(
    storage_key: StorageKey,
    items_attr: str,
    new_item,
    match_attr: str,
):
    model = load_model(storage_key)
    items = getattr(model, items_attr)

    for i, existing in enumerate(items):
        if getattr(existing, match_attr) == getattr(new_item, match_attr):
            items[i] = new_item
            save_model(storage_key, model)
            return True

    items.append(new_item)
    save_model(storage_key, model)
    return False


def persist_gk_instance(instance: GkInstance) -> bool:
    return persist_model_item(
        StorageKey.INSTANCES,
        "instances",
        instance,
        "base_url",
    )


def persist_keypair(keypair: GkKeyPair) -> bool:
    return persist_model_item(
        StorageKey.KEYPAIRS,
        "keypairs",
        keypair,
        "instance_base_url",
    )


def persist_apikey(key: GkApiKey) -> bool:
    return persist_model_item(
        StorageKey.APIKEYS,
        "api_keys",
        key,
        "instance_base_url",
    )
