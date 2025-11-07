def test_add_command_parsing(parser):
    args = parser.parse_args(["add"])
    assert args.command == "add"
    assert hasattr(args, "handler")


def test_list_command_parsing(parser):
    args = parser.parse_args(["list"])
    assert args.command == "list"
    assert hasattr(args, "handler")
    assert args.active == False


def test_list_command_parsing_with_active(parser):
    args = parser.parse_args(["list", "-a"])
    assert args.command == "list"
    assert hasattr(args, "handler")
    assert args.active == True
