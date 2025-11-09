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
    args = parser.parse_args(["keygen"])
    assert args.command == "keygen"
    assert hasattr(args, "handler")


def test_apikey_command_parsing(parser):
    args = parser.parse_args(["apikey"])
    assert args.command == "apikey"
    assert hasattr(args, "handler")
    assert args.instance is None


def test_apikey_command_parsing_with_instance_short_flag(parser):
    args = parser.parse_args(["apikey", "-i", "test"])
    assert args.command == "apikey"
    assert hasattr(args, "handler")
    assert args.instance == "test"


def test_apikey_command_parsing_with_instance_full_flag(parser):
    args = parser.parse_args(["apikey", "--instance", "test1"])
    assert args.command == "apikey"
    assert hasattr(args, "handler")
    assert args.instance == "test1"


def test_proxy_command_parsing(parser):
    args = parser.parse_args(["proxy", "GET", "users"])
    assert args.command == "proxy"
    assert hasattr(args, "handler")
    assert args.method == "GET"
    assert args.path == "users"
    assert args.instance is None
    assert args.body is None


def test_proxy_command_parsing_with_instance_short_flag(parser):
    args = parser.parse_args(["proxy", "POST", "api/items", "-i", "test_instance"])
    assert args.command == "proxy"
    assert hasattr(args, "handler")
    assert args.method == "POST"
    assert args.path == "api/items"
    assert args.instance == "test_instance"
    assert args.body is None


def test_proxy_command_parsing_with_instance_full_flag(parser):
    args = parser.parse_args(["proxy", "DELETE", "v1/resource", "--instance", "prod"])
    assert args.command == "proxy"
    assert hasattr(args, "handler")
    assert args.method == "DELETE"
    assert args.path == "v1/resource"
    assert args.instance == "prod"


def test_proxy_command_parsing_with_body_short_flag(parser):
    args = parser.parse_args(["proxy", "POST", "items", "-b", '{"key": "value"}'])
    assert args.command == "proxy"
    assert hasattr(args, "handler")
    assert args.method == "POST"
    assert args.path == "items"
    assert args.body == '{"key": "value"}'
