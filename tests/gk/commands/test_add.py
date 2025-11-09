import pytest
from gk.commands import add
from gk.models.gk_instance import GkInstance, GkInstances
from gk.storage import StorageKey, load_model, save_model


@pytest.mark.parametrize(
    "inputs,expected_active",
    [
        (["http://new.com", "test", "", "", "", "", "y"], True),
        (
            ["http://another.com", "test2", "", "x-client-id", "x-api-key", "", "n"],
            False,
        ),
    ],
)
def test_add_new_instance(console, inputs, expected_active, console_input):
    console_input(inputs)

    args = type("Args", (), {})()
    add.handle(args, console)

    instances = load_model(StorageKey.INSTANCES).instances
    assert len(instances) == 1
    assert instances[0].base_url == inputs[0]
    assert instances[0].active == expected_active

    keypairs = load_model(StorageKey.KEYPAIRS).keypairs
    assert len(keypairs) == 1
    assert keypairs[0].instance_base_url == instances[0].base_url


def test_add_overwrite_instance(console, console_input):
    # pre-populate storage with an instance
    existing = GkInstance(
        base_url="http://existing.com",
        client_id="test",
        active=False,
    )

    save_model(StorageKey.INSTANCES, GkInstances(instances=[existing]))

    inputs = [
        "http://existing.com",
        "y",
        "hello",
        "",
        "x-client-id",
        "x-api-key",
        "",
        "y",
    ]
    console_input(inputs)

    args = type("Args", (), {})()
    add.handle(args, console)

    instances = load_model(StorageKey.INSTANCES).instances
    assert len(instances) == 1
    assert instances[0].base_url == "http://existing.com"
    assert instances[0].active is True
    assert instances[0].client_id == "hello"

    keypairs = load_model(StorageKey.KEYPAIRS).keypairs
    assert len(keypairs) == 1
    assert keypairs[0].instance_base_url == instances[0].base_url
