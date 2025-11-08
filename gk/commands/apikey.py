from rich.console import Console
from app.models import ChallengeRequest, ChallengeResponse
from gk.models.gk_instance import GkInstance
from gk.commands import list_ as list_mod
import httpx


def add_subparser(subparsers):
    parser = subparsers.add_parser(
        "apikey",
        help="Fetch an apikey from a gatekeeper instance",
    )
    parser.add_argument(
        "-i",
        "--instance",
        help="Base URL of the Gatekeeper instance. Active instance is used if not specified",
    )
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    pass


def request_challenge(instance: GkInstance) -> ChallengeResponse:
    req = ChallengeRequest(
        client_id=instance.client_id,
    )
