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

    found = any(instance.base_url == args.base_url for instance in instances.instances)

    if not found:
        console.print(f"[yellow]Instance not found:[/yellow] {args.base_url}")
        sys.exit(1)

    changed = False

    for instance in instances.instances:
        if instance.base_url == args.base_url:
            if not instance.active:
                instance.active = True
                changed = True
        else:
            if instance.active:
                instance.active = False
                changed = True

    if changed:
        save_model(StorageKey.INSTANCES, instances)
        console.print(f"[green]Activated instance:[/green] {args.base_url}")
    else:
        console.print(f"[blue]Instance already active:[/blue] {args.base_url}")
