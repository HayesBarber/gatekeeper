from rich.console import Console


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
    pass
