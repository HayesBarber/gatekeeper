from pathlib import Path
import json

DATA_DIR = Path.home() / ".gk"
INSTANCES = DATA_DIR / "instances.json"


def ensure_data_dir():
    DATA_DIR.mkdir(parents=True, exist_ok=True)


def load_json(file_path: Path) -> dict:
    if not file_path.exists():
        return {}
    with open(file_path, "r") as f:
        return json.load(f)


def save_json(file_path: Path, data: dict):
    with open(file_path, "w") as f:
        json.dump(data, f, indent=2)
