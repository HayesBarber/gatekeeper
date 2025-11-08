from gk.commands import list_ as list_cmd
from gk.models.gk_instance import GkInstance, GkInstances
from gk.storage import StorageKey, save_model
import pytest


def test_list_no_instances(console):
    save_model(StorageKey.INSTANCES, GkInstances(instances=[]))

    args = type("Args", (), {})()
    args.active = False

    list_cmd.handle(args, console)
    output = console.export_text()
    assert "[]" in output


def test_list_multiple_instances(console):
    instances = [
        GkInstance(
            base_url="http://one.com",
            client_id="test1",
            active=False,
        ),
        GkInstance(
            base_url="http://two.com",
            client_id="test2",
            active=True,
        ),
    ]
    save_model(StorageKey.INSTANCES, GkInstances(instances=instances))

    args = type("Args", (), {})()
    args.active = False

    list_cmd.handle(args, console)
    output = console.export_text()
    assert "http://one.com" in output
    assert "http://two.com" in output


def test_list_active_instance_only(console):
    instances = [
        GkInstance(
            base_url="http://one.com",
            client_id="test1",
            active=False,
        ),
        GkInstance(
            base_url="http://two.com",
            client_id="test2",
            active=True,
        ),
    ]
    save_model(StorageKey.INSTANCES, GkInstances(instances=instances))

    args = type("Args", (), {})()
    args.active = True

    with pytest.raises(SystemExit):
        list_cmd.handle(args, console)

    output = console.export_text()
    assert "http://two.com" in output
    assert "http://one.com" not in output
