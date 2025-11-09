from rich.console import Console
from app.models import (
    ChallengeRequest,
    ChallengeResponse,
    ChallengeVerificationRequest,
    ChallengeVerificationResponse,
)
from gk.models.gk_instance import GkInstance
from gk.models.gk_keypair import GkKeyPair
from gk.models.gk_apikey import GkApiKey, GkApiKeys
from gk.commands import list_ as list_mod, keygen
from gk import storage
import httpx
import sys
from curveauth.signatures import sign_message
from datetime import datetime, timezone


def add_subparser(subparsers):
    parser = subparsers.add_parser(
        "apikey",
        help="Outputs the gatekeeper instance API key, fetching a new one if the current key has expired",
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
        console.print("[yellow]Instance not found[/yellow]")
        sys.exit(1)

    curr_key = get_apikey_for_instance(instance)

    if curr_key and not apikey_is_expired(curr_key):
        console.print_json(curr_key.api_key.model_dump_json())
        sys.exit(0)

    api_key, error = fetch_api_key(instance)

    if error:
        console.print_json(data=error)
        sys.exit(1)

    key: GkApiKey = GkApiKey(
        instance_base_url=instance.base_url,
        api_key=api_key,
    )
    storage.persist_apikey(key)
    console.print_json(api_key.model_dump_json())


def get_apikey_for_instance(instance: GkInstance) -> GkApiKey | None:
    apikeys: GkApiKeys = storage.load_model(storage.StorageKey.APIKEYS)

    for key in apikeys.api_keys:
        if key.instance_base_url == instance.base_url:
            return key

    return None


def apikey_is_expired(key: GkApiKey) -> bool:
    return key.api_key.expires_at < datetime.now(timezone.utc)


def fetch_api_key(instance: GkInstance) -> tuple[ChallengeVerificationResponse, object]:
    challenge_res, error = request_challenge(instance)
    if error:
        return None, error

    keypair = keygen.get_keypair_for_instance(instance)
    if not keypair:
        return None, {"error": "No keypair found"}

    verification_req = sign_challenge(instance, challenge_res, keypair)
    verification_res, error = request_challenge_verification(instance, verification_req)
    if error:
        return None, error

    return verification_res, None


def build_headers(instance: GkInstance) -> dict:
    headers = {
        instance.client_id_header: instance.client_id,
        **instance.other_headers,
    }
    return headers


def request_challenge(
    instance: GkInstance,
) -> tuple[ChallengeResponse, object]:
    req = ChallengeRequest(
        client_id=instance.client_id,
    )
    response = httpx.post(
        f"{instance.base_url}/challenge/",
        headers=build_headers(instance),
        json=req.model_dump(),
    )

    if response.status_code != 200:
        return (None, response.json())

    return (ChallengeResponse.model_validate(response.json()), None)


def sign_challenge(
    instance: GkInstance,
    challenge: ChallengeResponse,
    keypair: GkKeyPair,
) -> ChallengeVerificationRequest:
    signature = sign_message(challenge.challenge, keypair.private_key.decode("utf-8"))

    return ChallengeVerificationRequest(
        signature=signature,
        client_id=instance.client_id,
        challenge_id=challenge.challenge_id,
    )


def request_challenge_verification(
    instance: GkInstance,
    req: ChallengeVerificationRequest,
) -> tuple[ChallengeVerificationResponse, object]:
    response = httpx.post(
        f"{instance.base_url}/challenge/verify",
        headers=build_headers(instance),
        json=req.model_dump(),
    )

    if response.status_code != 200:
        return (None, response.json())

    return (ChallengeVerificationResponse.model_validate(response.json()), None)
