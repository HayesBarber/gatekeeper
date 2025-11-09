from gk.commands import add, proxy, list_
import json


def test_proxy_happy_path(console, console_input, local_base_url, seed_user):
    client_id = "proxy_test_client"
    inputs = [
        local_base_url,
        client_id,
        "",
        "",
        "",
        "User-Agent",
        "test-user-agent",
        "",
        "y",
    ]
    console_input(inputs)
    args = type("Args", (), {})()
    add.handle(args, console)

    public_key = list_.get_active_instance().public_key
    seed_user(client_id, public_key)

    for i in range(1, 3):
        # Proxy GET /echo
        args = type("Args", (), {})()
        args.method = "GET"
        args.path = f"/api{i}/echo"
        args.instance = None
        args.body = None
        proxy.handle(args, console)
        output = console.export_text()
        assert "GET" in output
        assert "path" in output
        assert "/echo" in output

        # Proxy POST /echo
        args = type("Args", (), {})()
        args.method = "POST"
        args.path = f"/api{i}/echo"
        args.instance = None
        body = json.dumps({"msg": "hi"})
        args.body = body
        proxy.handle(args, console)
        output = console.export_text()
        assert "POST" in output
        assert "msg" in output
        assert "hi" in output
