import argparse
from gk.commands import add, list_, keygen, apikey, proxy


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="srl")
    subparsers = parser.add_subparsers(dest="command")

    for element in [
        add,
        list_,
        keygen,
        apikey,
        proxy,
    ]:
        element.add_subparser(subparsers)

    return parser
