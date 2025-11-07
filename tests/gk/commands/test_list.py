from gk.commands import list_ as list_cmd
from gk.models.gk_instance import GkInstance, GkInstances
from gk.storage import StorageKey


def test_list_no_instances(console, tmp_storage, monkeypatch):
    load_model, save_model, storage = tmp_storage
    storage[StorageKey.INSTANCES] = GkInstances(instances=[])

    monkeypatch.setattr(list_cmd, "load_model", load_model)

    args = type("Args", (), {})()
    args.active = False

    list_cmd.handle(args, console)
    output = console.export_text()
    assert "No instances found." in output


def test_list_multiple_instances(console, tmp_storage, monkeypatch):
    load_model, save_model, storage = tmp_storage
    instances = [
        GkInstance(base_url="http://one.com", active=False),
        GkInstance(base_url="http://two.com", active=True),
    ]
    storage[StorageKey.INSTANCES] = GkInstances(instances=instances)

    monkeypatch.setattr(list_cmd, "load_model", load_model)

    args = type("Args", (), {})()
    args.active = False

    list_cmd.handle(args, console)
    output = console.export_text()
    assert "http://one.com" in output
    assert "http://two.com" in output
    assert "yes" in output


def test_list_active_instance_only(console, tmp_storage, monkeypatch):
    load_model, save_model, storage = tmp_storage
    instances = [
        GkInstance(base_url="http://one.com", active=False),
        GkInstance(base_url="http://two.com", active=True),
    ]
    storage[StorageKey.INSTANCES] = GkInstances(instances=instances)

    monkeypatch.setattr(list_cmd, "load_model", load_model)

    args = type("Args", (), {})()
    args.active = True

    list_cmd.handle(args, console)
    output = console.export_text()
    assert "Active Instance:" in output
    assert "http://two.com" in output
    assert "http://one.com" not in output
