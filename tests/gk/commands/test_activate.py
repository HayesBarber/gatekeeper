from gk.commands import activate
from gk.models.gk_instance import GkInstances, GkInstance
from gk.storage import StorageKey, save_model, load_model


def test_activate_happy_path(console):
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
    args.base_url = "http://one.com"

    activate.handle(args, console)
    output = console.export_text()

    assert "Activated instance: http://one.com" in output
    stored = load_model(StorageKey.INSTANCES).instances
    assert len(stored) == 2

    one = next(i for i in stored if i.base_url == "http://one.com")
    two = next(i for i in stored if i.base_url == "http://two.com")

    assert one and one.active
    assert two and not two.active


def test_activate_already_active(console):
    instances = [
        GkInstance(
            base_url="http://one.com",
            client_id="test1",
            active=True,
        ),
        GkInstance(
            base_url="http://two.com",
            client_id="test2",
            active=False,
        ),
    ]
    save_model(StorageKey.INSTANCES, GkInstances(instances=instances))

    args = type("Args", (), {})()
    args.base_url = "http://one.com"

    activate.handle(args, console)
    output = console.export_text()

    assert "Instance already active: http://one.com" in output
    stored = load_model(StorageKey.INSTANCES).instances

    one = next(i for i in stored if i.base_url == "http://one.com")
    two = next(i for i in stored if i.base_url == "http://two.com")

    assert one and one.active
    assert two and not two.active
