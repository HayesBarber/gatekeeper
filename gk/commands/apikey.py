from rich.console import Console
from app.models import ChallengeRequest, ChallengeResponse, ChallengeVerificationRequest
from gk.models.gk_instance import GkInstance
from gk.models.gk_keypair import GkKeyPair
from gk.commands import list_ as list_mod, keygen
import httpx
import sys
from curveauth.signatures import sign_message


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

    challeng_res = request_challenge(instance, console)

    keypair = keygen.get_keypair_for_instance(instance)

    if not keypair:
        console.print("[yellow]No keypair found[/yellow]")
        sys.exit(1)

    verification_req = sign_challenge(
        instance,
        challeng_res,
        keypair,
    )


def request_challenge(
    instance: GkInstance,
    console: Console,
) -> ChallengeResponse:
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
        console.print_json(response.json())
        sys.exit(1)

    return ChallengeResponse.model_validate(response.json())


def sign_challenge(
    instance: GkInstance,
    challenge: ChallengeResponse,
    keypair: GkKeyPair,
) -> ChallengeVerificationRequest:
    signature = sign_message(challenge, keypair.private_key.decode("utf-8"))

    return ChallengeVerificationRequest(
        signature=signature,
        client_id=instance.client_id,
        challenge_id=challenge.challenge_id,
    )
