from rich.console import Console
from curveauth.keys import ECCKeyPair


def add_subparser(subparsers):
    parser = subparsers.add_parser("keygen", help="Generate a ECC keypair")
    parser.add_argument("instance", type=str, help="The gatekeeper instanse base URL")
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    keypair = ECCKeyPair.generate()
