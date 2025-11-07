from rich.console import Console
from gk.models.gk_instance import GkInstance, GkInstances
from gk.storage import StorageKey, ensure_data_dir, load_model, save_model


def add_subparser(subparsers):
    parser = subparsers.add_parser("add", help="Add a gatekeeper instance")
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    base_url = None
    while not base_url:
        base_url = console.input("Base URL of the gatekeeper instance: ")
    api_key_header = console.input(
        "API key header name (e.g. x-api-key) Enter to skip: "
    )
    client_id_header = console.input(
        "Client ID header name (e.g. x-requestor-id) Enter to skip: "
    )
    active = console.input("Set as active? y/n: ")

    is_active = str(active).strip().lower().startswith("y")

    kwargs = {"name": base_url, "active": is_active}
    if api_key_header:
        kwargs["api_key_header"] = api_key_header
    if client_id_header:
        kwargs["client_id_header"] = client_id_header

    instance = GkInstance(**kwargs)

    instances_model: GkInstances = load_model(StorageKey.INSTANCES)
    for i, existing in enumerate(instances_model.instances):
        if existing.name == instance.name:
            instances_model.instances[i] = instance
            save_model(StorageKey.INSTANCES, instances_model)
            console.print(
                f"Overwrote instance '{instance.name}' (active={instance.active})"
            )
            break
    else:
        instances_model.instances.append(instance)
        save_model(StorageKey.INSTANCES, instances_model)
        console.print(f"Added instance '{instance.name}' (active={instance.active})")
