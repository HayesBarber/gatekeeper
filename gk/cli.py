import argparse
import importlib
import pkgutil
import gk.commands


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="gk")
    subparsers = parser.add_subparsers(dest="command")

    for _, module_name, _ in pkgutil.iter_modules(gk.commands.__path__):
        module = importlib.import_module(f"gk.commands.{module_name}")
        if hasattr(module, "add_subparser"):
            module.add_subparser(subparsers)

    return parser
