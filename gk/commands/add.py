from rich.console import Console
from curveauth.keys import ECCKeyPair
from gk.models.gk_instance import GkInstance, GkInstances
from gk.storage import StorageKey, load_model, save_model
from gk.commands import keygen
import sys


def add_subparser(subparsers):
    parser = subparsers.add_parser("add", help="Add a gatekeeper instance")
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    instances_model: GkInstances = load_model(StorageKey.INSTANCES)
    base_url, client_id, client_id_header, api_key_header, is_active = gather_input(
        console, instances_model
    )

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

    keypair = keygen.generate_keypair_for_instance(instance)
    keygen.persist_keypair(keypair)

    instance.public_key = ECCKeyPair.load_private_pem(
        keypair.private_key
    ).public_key_raw_base64()

    persist_gk_instance(instance, instances_model)
    console.print_json(instance.model_dump_json())


def gather_input(console: Console, instances_model: GkInstances):
    base_url = None
    while not base_url:
        base_url = console.input("Base URL of the gatekeeper instance: ")
    exists = instance_exists(base_url, instances_model)
    if exists:
        should_continue = None
        while should_continue != "y" and should_continue != "n":
            should_continue = console.input("Instance exists, overwrite? y/n: ")
        if should_continue == "n":
            sys.exit(1)
    client_id = None
    while not client_id:
        client_id = console.input("Client ID: ")
    client_id_header = console.input(
        "Client ID header name (e.g. x-requestor-id) Enter to skip: "
    )
    api_key_header = console.input(
        "API key header name (e.g. x-api-key) Enter to skip: "
    )
    active = None
    while active != "y" and active != "n":
        active = console.input("Set as active? y/n: ")
    is_active = active == "y"
    return base_url, client_id, client_id_header, api_key_header, is_active


def instance_exists(
    base_url: str,
    instances_model: GkInstances,
) -> bool:
    for existing in instances_model.instances:
        if existing.base_url == base_url:
            return True
    return False


def persist_gk_instance(
    instance: GkInstance,
    instances_model: GkInstances | None = None,
) -> bool:
    """
    returns true if keypair overwrote an existing
    """
    if not instances_model:
        instances_model: GkInstances = load_model(StorageKey.INSTANCES)

    for i, existing in enumerate(instances_model.instances):
        if existing.base_url == instance.base_url:
            instances_model.instances[i] = instance
            save_model(StorageKey.INSTANCES, instances_model)
            return True

    instances_model.instances.append(instance)
    save_model(StorageKey.INSTANCES, instances_model)
    return False
