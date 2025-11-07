from rich.console import Console


def add_subparser(subparsers):
    parser = subparsers.add_parser("list", help="List gatekeeper instances")
    parser.add_argument(
        "-a",
        "--active",
        action="store_true",
        dest="active",
        help="List the active instance",
    )
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    pass
