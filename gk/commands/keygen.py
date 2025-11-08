from rich.console import Console
from curveauth.keys import ECCKeyPair
from gk.models.gk_instance import GkInstance
from gk.models.gk_keypair import GkKeyPair


def add_subparser(subparsers):
    parser = subparsers.add_parser("keygen", help="Generate a ECC keypair")
    parser.add_argument("instance", type=str, help="The gatekeeper instanse base URL")
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    pass


def generate_keypair_for_instance(instance: GkInstance) -> GkKeyPair:
    instance_base_url = instance.base_url
    keypair = ECCKeyPair.generate()
    public_key = keypair.public_pem()
    private_key = keypair.private_pem()

    return GkKeyPair(
        instance_base_url,
        public_key,
        private_key,
    )
