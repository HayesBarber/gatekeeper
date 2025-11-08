from rich.console import Console
from gk.models.gk_instance import GkInstance, GkInstances
from gk.storage import StorageKey, load_model, save_model
from gk.commands import keygen
import sys


def add_subparser(subparsers):
    parser = subparsers.add_parser("add", help="Add a gatekeeper instance")
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    base_url = None
    while not base_url:
        base_url = console.input("Base URL of the gatekeeper instance: ")
    client_id = None
    while not client_id:
        client_id = console.input("Client ID: ")
    client_id_header = console.input(
        "Client ID header name (e.g. x-requestor-id) Enter to skip: "
    )
    api_key_header = console.input(
        "API key header name (e.g. x-api-key) Enter to skip: "
    )
    active = console.input("Set as active? y/n: ")

    is_active = str(active).strip().lower().startswith("y")

    kwargs = {
        "base_url": base_url,
        "client_id": client_id,
        "active": is_active,
    }
    if api_key_header:
        kwargs["api_key_header"] = api_key_header
    if client_id_header:
        kwargs["client_id_header"] = client_id_header

    instance = GkInstance(**kwargs)
    instances_model: GkInstances = load_model(StorageKey.INSTANCES)

    exists = instance_exists(instance, instances_model)
    if exists:
        should_continue = console.input("Instance exists, overwrite? y/n: ")
        if not should_continue.strip().lower().startswith("y"):
            sys.exit(1)

    for i, existing in enumerate(instances_model.instances):
        if existing.base_url == instance.base_url:
            instances_model.instances[i] = instance
            save_model(StorageKey.INSTANCES, instances_model)
            break
    else:
        instances_model.instances.append(instance)
        save_model(StorageKey.INSTANCES, instances_model)

    console.print_json(instance.model_dump_json())

    args.instance = instance.base_url
    keygen.handle(args, console)


def instance_exists(
    instance: GkInstance,
    instances_model: GkInstances,
) -> bool:
    for existing in instances_model.instances:
        if existing.base_url == instance.base_url:
            return True
    return False
