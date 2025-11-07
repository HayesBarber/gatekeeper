from pathlib import Path
import json
from enum import Enum

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


def load_json(key: StorageKey) -> dict[str]:
    file_path = path_for(key)
    if not file_path.exists():
        return {}
    with open(file_path, "r") as f:
        return json.load(f)


def save_json(key: StorageKey, data: dict[str]):
    file_path = path_for(key)
    with open(file_path, "w") as f:
        json.dump(data, f, indent=2)
