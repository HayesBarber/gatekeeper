import pytest
from gk import cli
from gk.models.gk_instance import GkInstance, GkInstances
from gk.storage import StorageKey
from rich.console import Console


@pytest.fixture
def parser():
    return cli.build_parser()


@pytest.fixture
def console():
    return Console(record=True)


@pytest.fixture
def tmp_storage():
    storage = {}

    def _load(key: StorageKey):
        return storage.get(key, GkInstances())

    def _save(key: StorageKey, model):
        storage[key] = model

    return _load, _save, storage
