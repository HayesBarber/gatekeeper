import pytest
from gk import cli
from rich.console import Console


@pytest.fixture
def parser():
    return cli.build_parser()


@pytest.fixture
def console():
    return Console(record=True)
