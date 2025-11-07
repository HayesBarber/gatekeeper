from rich.console import Console


def add_subparser(subparsers):
    parser = subparsers.add_parser("add", help="Add a gatekeeper instance")
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    base_url = console.input("Base URL of the gatekeeper instance: ")
    api_key_header = console.input("API key header name (e.g. x-api-key): ")
    client_id_header = console.input("Client ID header name (e.g. x-requestor-id): ")
