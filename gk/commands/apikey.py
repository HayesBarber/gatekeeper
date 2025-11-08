from rich.console import Console
from app.models import ChallengeRequest, ChallengeResponse
from gk.models.gk_instance import GkInstance
from gk.commands import list_ as list_mod
import httpx
import sys


def add_subparser(subparsers):
    parser = subparsers.add_parser(
        "apikey",
        help="Fetch an apikey from a gatekeeper instance",
    )
    parser.add_argument(
        "-i",
        "--instance",
        dest="instance",
        type=str,
        help="Base URL of the Gatekeeper instance. Active instance is used if not specified",
    )
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    instance = None

    if args.instance:
        instance = list_mod.get_instance_by_base_url(args.instance)
    else:
        instance = list_mod.get_active_instance()

    if not instance:
        console.print("[yellow]No instance found[/yellow]")
        sys.exit(1)

    res = request_challenge(instance)
    console.print_json(res.model_dump_json())


def request_challenge(instance: GkInstance) -> ChallengeResponse:
    req = ChallengeRequest(
        client_id=instance.client_id,
    )
    headers = {
        "Content-Type": "application/json",
        instance.client_id_header: instance.client_id,
        **instance.other_headers,
    }
    response = httpx.post(
        f"{instance.base_url}/challenge/",
        headers=headers,
        json=req.model_dump(),
    )

    if response.status_code != 200:
        print(response.json())
        sys.exit(1)

    return ChallengeResponse.model_validate(response.json())
