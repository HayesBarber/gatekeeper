from rich.console import Console
from gk.commands import list_ as list_mod, apikey
from gk.models.gk_apikey import GkApiKey
from gk import storage
import httpx
import json
import sys


def add_subparser(subparsers):
    parser = subparsers.add_parser(
        "proxy",
        help="Make a proxy request though gatekeeper",
    )
    parser.add_argument("method", choices=["GET", "POST", "PUT", "DELETE", "PATCH"])
    parser.add_argument("path", help="API path (relative to instance base URL)")
    parser.add_argument("-b", "--body", dest="body", help="JSON body or @file.json")
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

    curr_key = apikey.get_apikey_for_instance(instance)

    if not curr_key or apikey.apikey_is_expired(curr_key):
        api_key, error = apikey.fetch_api_key(instance)
        if error:
            console.print_json(data=error)
            sys.exit(1)

        curr_key = GkApiKey(
            instance_base_url=instance.base_url,
            api_key=api_key,
        )
        storage.persist_apikey(curr_key)

    headers = apikey.build_headers(instance)
    headers[instance.api_key_header] = curr_key.api_key.api_key

    url = f"{instance.base_url.rstrip('/')}/{args.path.lstrip('/')}"

    body = None
    if getattr(args, "body", None):
        if args.body.startswith("@"):
            filename = args.body[1:]
            try:
                with open(filename, "r") as f:
                    body = json.load(f)
            except Exception as e:
                console.print(f"[red]Failed to read body file: {e}[/red]")
                sys.exit(1)
        else:
            try:
                body = json.loads(args.body)
            except Exception as e:
                console.print(f"[red]Failed to parse JSON body: {e}[/red]")
                sys.exit(1)

    try:
        response = httpx.request(args.method, url, headers=headers, json=body)
    except Exception as e:
        console.print(f"[red]HTTP request failed: {e}[/red]")
        sys.exit(1)

    try:
        data = response.json()
    except Exception as e:
        console.print(f"[red]Failed to parse response JSON: {e}[/red]")
        sys.exit(1)

    if response.status_code != 200:
        console.print_json(data)
        sys.exit(1)
    else:
        console.print_json(data)
