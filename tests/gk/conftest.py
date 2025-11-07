import pytest
from gk import cli


@pytest.fixture
def parser():
    return cli.build_parser()
