from gk.cli import build_parser
from rich.console import Console


def main():
    parser = build_parser()
    args = parser.parse_args()
    console = Console()

    if hasattr(args, "handler"):
        args.handler(args, console)
    else:
        parser.print_help()
