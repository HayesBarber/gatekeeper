import argparse
from gk.commands import add, list_, keygen, apikey


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="srl")
    subparsers = parser.add_subparsers(dest="command")

    add.add_subparser(subparsers)
    list_.add_subparser(subparsers)
    keygen.add_subparser(subparsers)
    apikey.add_subparser(subparsers)

    return parser
