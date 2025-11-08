import pytest
from gk.commands import add
from gk.models.gk_instance import GkInstance, GkInstances
from gk.storage import StorageKey


@pytest.mark.parametrize(
    "inputs,expected_active",
    [
        (["http://new.com", "test", "", "", "y"], True),
        (["http://another.com", "test2", "x-client-id", "x-api-key", "n"], False),
    ],
)
def test_add_new_instance(console, tmp_storage, inputs, expected_active, monkeypatch):
    load_model, save_model, storage = tmp_storage

    monkeypatch.setattr(add, "load_model", load_model)
    monkeypatch.setattr(add, "save_model", save_model)

    # Patch console.input to return items from inputs list
    input_iter = iter(inputs)
    monkeypatch.setattr(console, "input", lambda prompt="": next(input_iter))

    args = type("Args", (), {})()
    add.handle(args, console)

    instances = storage[StorageKey.INSTANCES].instances
    assert len(instances) == 1
    assert instances[0].base_url == inputs[0]
    assert instances[0].active == expected_active


def test_add_overwrite_instance(console, tmp_storage, monkeypatch):
    load_model, save_model, storage = tmp_storage

    # pre-populate storage with an instance
    existing = GkInstance(
        base_url="http://existing.com",
        client_id="test",
        active=False,
    )
    storage[StorageKey.INSTANCES] = GkInstances(instances=[existing])

    monkeypatch.setattr(add, "load_model", load_model)
    monkeypatch.setattr(add, "save_model", save_model)

    inputs = ["http://existing.com", "y", "hello", "x-api-key", "x-client-id", "y"]
    input_iter = iter(inputs)
    monkeypatch.setattr(console, "input", lambda prompt="": next(input_iter))

    args = type("Args", (), {})()
    add.handle(args, console)

    instances = storage[StorageKey.INSTANCES].instances
    assert len(instances) == 1
    assert instances[0].base_url == "http://existing.com"
    assert instances[0].active is True
    assert instances[0].client_id == "hello"
