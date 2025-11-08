import sys
import pytest
from gk import main
import argparse


def test_main_calls_ensure_data_dir(monkeypatch):
    called = {}
    monkeypatch.setattr(sys, "argv", ["prog"])
    monkeypatch.setattr(
        main, "ensure_data_dir", lambda: called.setdefault("called", True)
    )

    main.main()

    assert called["called"] is True


def test_main_prints_help_when_no_command(monkeypatch, capsys):
    monkeypatch.setattr(sys, "argv", ["prog"])
    main.main()
    out, _ = capsys.readouterr()
    assert "usage:" in out


def test_main_raises_when_unknown_command(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["prog", "unknown"])
    with pytest.raises(SystemExit) as excinfo:
        main.main()
    assert excinfo.value.code == 2


def test_main_dispatches_to_handler(monkeypatch):
    called = {}

    def fake_handler(args, console):
        called["ok"] = (args, console)

    class FakeParser:
        def parse_args(self):
            ns = argparse.Namespace(command="keygen")
            ns.handler = fake_handler
            return ns

        def print_help(self):
            pass

    monkeypatch.setattr(main, "build_parser", lambda: FakeParser())

    main.main()

    assert "ok" in called
    args, _ = called["ok"]
    assert args.command == "keygen"
