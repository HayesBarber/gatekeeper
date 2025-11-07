from rich.console import Console
from gk.models.gk_instance import GkInstance, GkInstances
from gk.storage import StorageKey, load_model
from rich.table import Table


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
            console.print(
                f"[bold green]Active Instance:[/bold green] {active.base_url}"
            )
        else:
            console.print("[yellow]No active instance set.[/yellow]")
        return

    instances_model = get_instances()
    instances = instances_model.instances
    if not instances:
        console.print("[yellow]No instances found.[/yellow]")
        return

    table = Table(title="Gatekeeper Instances")
    table.add_column("Base URL", style="bold")
    table.add_column("Active", justify="center")

    for instance in instances:
        active_mark = "[green]yes[/green]" if instance.active else "no"
        url = (
            f"[green]{instance.base_url}[/green]"
            if instance.active
            else instance.base_url
        )
        table.add_row(url, active_mark)

    console.print(table)


def get_instances() -> GkInstances:
    instances_model: GkInstances = load_model(StorageKey.INSTANCES)
    return instances_model


def get_active_instance() -> GkInstance | None:
    instances = get_instances()

    for instance in instances.instances:
        if instance.active:
            return instance

    return None
