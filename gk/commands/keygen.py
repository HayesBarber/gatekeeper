from rich.console import Console
from curveauth.keys import ECCKeyPair
from gk.models.gk_instance import GkInstance
from gk.models.gk_keypair import GkKeyPair, GkKeyPairs
from gk.storage import StorageKey, load_model, save_model


def add_subparser(subparsers):
    parser = subparsers.add_parser("keygen", help="Generate a ECC keypair")
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    public_key, private_key = generate_keypair()
    console.print_json(
        data={
            "public_key": public_key.decode(),
            "private_key": private_key.decode(),
        }
    )


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
    public_key, private_key = generate_keypair()

    return GkKeyPair(
        instance_base_url=instance_base_url,
        public_key=public_key,
        private_key=private_key,
    )


def generate_keypair() -> tuple[bytes, bytes]:
    keypair = ECCKeyPair.generate()
    public_key = keypair.public_pem()
    private_key = keypair.private_pem()
    return (public_key, private_key)


def get_keypairs() -> GkKeyPairs:
    instances_model: GkKeyPairs = load_model(StorageKey.KEYPAIRS)
    return instances_model
