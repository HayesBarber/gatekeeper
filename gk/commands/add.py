from rich.console import Console


def add_subparser(subparsers):
    parser = subparsers.add_parser("add", help="Add a gatekeeper instance")
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    pass
