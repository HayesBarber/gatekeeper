from pathlib import Path
from enum import Enum
from typing import Type, Dict
from pydantic import BaseModel
from gk.models.gk_instance import GkInstances

DATA_DIR = Path.home() / ".gk"


class StorageKey(str, Enum):
    INSTANCES = "instances"


FILE_NAMES: dict[StorageKey, str] = {
    StorageKey.INSTANCES: "instances.json",
}


def ensure_data_dir():
    DATA_DIR.mkdir(parents=True, exist_ok=True)


def path_for(key: StorageKey) -> Path:
    return DATA_DIR / FILE_NAMES[key]


MODEL_FOR_KEY: Dict[StorageKey, Type[BaseModel]] = {
    StorageKey.INSTANCES: GkInstances,
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
