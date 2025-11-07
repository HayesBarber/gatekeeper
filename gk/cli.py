import argparse


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="srl")
    subparsers = parser.add_subparsers(dest="command")

    return parser
