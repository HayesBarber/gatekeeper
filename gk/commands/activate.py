import sys
from argparse import ArgumentParser, _SubParsersAction
from rich.console import Console
from gk.models.gk_instance import GkInstances
from gk.storage import StorageKey, load_model, save_model


def add_subparser(subparsers: _SubParsersAction) -> ArgumentParser:
    parser = subparsers.add_parser(
        "activate",
        help="Activate a Gatekeeper instance by its base URL",
    )
    parser.add_argument("base_url", type=str, help="The instance base URL to activate")
    parser.set_defaults(handler=handle)
    return parser


def handle(args, console: Console):
    instances: GkInstances = load_model(StorageKey.INSTANCES)
    instance = next(
        (i for i in instances.instances if i.base_url == args.base_url), None
    )
    if instance is None:
        console.print("[yellow]Instance not found[/yellow]")
        sys.exit(1)

    for i in instances.instances:
        i.active = False
    instance.active = True

    save_model(StorageKey.INSTANCES, instances)

    console.print(f"[green]Activated instance:[/green] {args.base_url}")
