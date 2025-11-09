from rich.console import Console
from curveauth.keys import ECCKeyPair
from gk.models.gk_instance import GkInstance, GkInstances
from gk.storage import StorageKey, load_model, persist_gk_instance, persist_keypair
from gk.commands import keygen
import sys


def add_subparser(subparsers):
    parser = subparsers.add_parser("add", help="Add a gatekeeper instance")
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    instances_model: GkInstances = load_model(StorageKey.INSTANCES)
    (
        base_url,
        proxy_path,
        client_id,
        client_id_header,
        api_key_header,
        is_active,
        other_headers,
    ) = gather_input(console, instances_model)

    kwargs = {
        "base_url": base_url,
        "client_id": client_id,
        "active": is_active,
    }
    if api_key_header:
        kwargs["api_key_header"] = api_key_header
    if client_id_header:
        kwargs["client_id_header"] = client_id_header
    if other_headers:
        kwargs["other_headers"] = other_headers
    if proxy_path:
        kwargs["proxy_path"] = proxy_path

    instance = GkInstance(**kwargs)

    keypair = keygen.generate_keypair_for_instance(instance)
    persist_keypair(keypair)

    instance.public_key = ECCKeyPair.load_private_pem(
        keypair.private_key
    ).public_key_raw_base64()

    persist_gk_instance(instance)
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
    proxy_path = console.input("Proxy path (default /proxy) Enter to skip: ")
    client_id_header = console.input(
        "Client ID header name (default x-requestor-id) Enter to skip: "
    )
    api_key_header = console.input(
        "API key header name (default x-api-key) Enter to skip: "
    )
    other_headers = {}
    while True:
        header_key = console.input("Other header key (press Enter to finish): ")
        if not header_key:
            break
        header_value = console.input(f"Value for header '{header_key}': ")
        other_headers[header_key] = header_value
    active = None
    while active != "y" and active != "n":
        active = console.input("Set as active? y/n: ")
    is_active = active == "y"
    return (
        base_url,
        proxy_path,
        client_id,
        client_id_header,
        api_key_header,
        is_active,
        other_headers,
    )


def instance_exists(
    base_url: str,
    instances_model: GkInstances,
) -> bool:
    for existing in instances_model.instances:
        if existing.base_url == base_url:
            return True
    return False
