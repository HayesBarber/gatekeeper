from rich.console import Console
from gk.models.gk_instance import GkInstance, GkInstances
from gk.storage import StorageKey, load_model


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


def get_instances() -> GkInstances:
    instances_model: GkInstances = load_model(StorageKey.INSTANCES)
    return instances_model


def get_active_instance() -> GkInstance | None:
    instances = get_instances()

    for instance in instances.instances:
        if instance.active:
            return instance

    return None
