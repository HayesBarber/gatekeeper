from rich.console import Console
from gk.models.gk_instance import GkInstance, GkInstances
from gk.storage import StorageKey, load_model
import sys


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
    if args.active:
        active = get_active_instance()
        if active:
            console.print_json(active.model_dump_json())
            sys.exit(0)
        else:
            console.print("[yellow]No active instance set.[/yellow]")
            sys.exit(1)

    instances_model = get_instances()
    console.print_json(instances_model.model_dump_json())


def get_instances() -> GkInstances:
    instances_model: GkInstances = load_model(StorageKey.INSTANCES)
    return instances_model


def get_instance_by_base_url(base_url: str) -> GkInstance | None:
    instances = get_instances()

    for instance in instances.instances:
        if instance.base_url == base_url:
            return instance

    return None


def get_active_instance() -> GkInstance | None:
    instances = get_instances()

    for instance in instances.instances:
        if instance.active:
            return instance

    return None
