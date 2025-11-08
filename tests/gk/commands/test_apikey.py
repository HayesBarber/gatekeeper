from gk.storage import StorageKey, save_model
from gk.models.gk_instance import GkInstances, GkInstance
from gk.commands import apikey, add
import pytest


def test_apikey_no_instances(console):
    save_model(StorageKey.INSTANCES, GkInstances(instances=[]))

    args = type("Args", (), {})()
    args.instance = None
    with pytest.raises(SystemExit):
        apikey.handle(args, console)

    output = console.export_text()
    assert "Instance not found" in output


def test_apikey_invalid_instance(console):
    instances = [
        GkInstance(
            base_url="http://one.com",
            client_id="test1",
            active=False,
        ),
    ]
    save_model(StorageKey.INSTANCES, GkInstances(instances=instances))

    args = type("Args", (), {})()
    args.instance = "invalid"
    with pytest.raises(SystemExit):
        apikey.handle(args, console)

    output = console.export_text()
    assert "Instance not found" in output


def test_apikey_happy_path(console, console_input, local_base_url, seeded_user):
    client_id, _ = seeded_user
    inputs = [
        local_base_url,
        client_id,
        "x-client-id",
        "x-api-key",
        "User-Agent",
        "test-user-agent",
        "",
        "y",
    ]
    console_input(inputs)

    args = type("Args", (), {})()
    add.handle(args, console)

    args = type("Args", (), {})()
    args.instance = None
    with pytest.raises(SystemExit):
        apikey.handle(args, console)
