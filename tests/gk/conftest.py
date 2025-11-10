import pytest
from gk import cli
from rich.console import Console
from gk import storage


@pytest.fixture(autouse=True)
def _tmp_data_dir(tmp_path, monkeypatch):
    tmp_dir = tmp_path / ".gk"
    tmp_dir.mkdir(parents=True, exist_ok=True)
    monkeypatch.setattr(storage, "DATA_DIR", tmp_dir)
    monkeypatch.setattr(storage, "KEY_FILE", tmp_dir / ".key")
    return tmp_dir


@pytest.fixture
def parser():
    return cli.build_parser()


@pytest.fixture
def console():
    return Console(record=True)


@pytest.fixture
def console_input(monkeypatch, console):

    def _mock(inputs: list):
        input_iter = iter(inputs)
        monkeypatch.setattr(console, "input", lambda prompt="": next(input_iter))

    return _mock
