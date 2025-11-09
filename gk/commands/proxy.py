from rich.console import Console


def add_subparser(subparsers):
    parser = subparsers.add_parser(
        "proxy",
        help="Make a proxy request though gatekeeper",
    )
    parser.add_argument("method", choices=["GET", "POST", "PUT", "DELETE", "PATCH"])
    parser.add_argument("path", help="API path (relative to instance base URL)")
    parser.add_argument("--body", dest="body", help="JSON body or @file.json")
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    pass
