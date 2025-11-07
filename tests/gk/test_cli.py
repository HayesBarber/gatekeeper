import pytest


def test_add_command_parsing(parser):
    args = parser.parse_args(["add"])
    assert args.command == "add"
    assert hasattr(args, "handler")


def test_list_command_parsing(parser):
    args = parser.parse_args(["list"])
    assert args.command == "list"
    assert hasattr(args, "handler")
    assert not args.active


def test_list_command_parsing_with_active(parser):
    args = parser.parse_args(["list", "-a"])
    assert args.command == "list"
    assert hasattr(args, "handler")
    assert args.active


def test_keygen_command_parsing(parser):
    args = parser.parse_args(["keygen", "testing"])
    assert args.command == "keygen"
    assert hasattr(args, "handler")
    assert args.instance == "testing"


def test_keygen_command_parsing_no_instance_provided(parser):
    with pytest.raises(SystemExit):
        parser.parse_args(["keygen"])
