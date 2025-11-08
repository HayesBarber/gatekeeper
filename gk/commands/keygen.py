from rich.console import Console
from curveauth.keys import ECCKeyPair
from gk.models.gk_instance import GkInstance
from gk.models.gk_keypair import GkKeyPair, GkKeyPairs
from gk.commands.list_ import get_instance_by_base_url
from gk.storage import StorageKey, load_model, save_model
import sys


def add_subparser(subparsers):
    parser = subparsers.add_parser("keygen", help="Generate a ECC keypair")
    parser.add_argument("instance", type=str, help="The gatekeeper instanse base URL")
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    instance = get_instance_by_base_url(args.instance)

    if not instance:
        console.print(f"[yellow]No instance found:[/yellow] {args.instance}")
        sys.exit(1)

    keypair = generate_keypair_for_instance(instance)
    overwrote: bool = persist_keypair(keypair)
    if overwrote:
        console.print(f"Overwrote keypair for '{keypair.instance_base_url}'")
    else:
        console.print(f"Added keypair for '{keypair.instance_base_url}'")


def persist_keypair(keypair: GkKeyPair) -> bool:
    """
    returns true if keypair overwrote an existing
    """
    instances_model: GkKeyPairs = get_keypairs()

    for i, existing in enumerate(instances_model.keypairs):
        if existing.instance_base_url == keypair.instance_base_url:
            instances_model.keypairs[i] = keypair
            save_model(StorageKey.KEYPAIRS, instances_model)
            return True

    instances_model.keypairs.append(keypair)
    save_model(StorageKey.KEYPAIRS, instances_model)
    return False


def generate_keypair_for_instance(instance: GkInstance) -> GkKeyPair:
    instance_base_url = instance.base_url
    keypair = ECCKeyPair.generate()
    public_key = keypair.public_pem()
    private_key = keypair.private_pem()

    return GkKeyPair(
        instance_base_url=instance_base_url,
        public_key=public_key,
        private_key=private_key,
    )


def get_keypairs() -> GkKeyPairs:
    instances_model: GkKeyPairs = load_model(StorageKey.KEYPAIRS)
    return instances_model
