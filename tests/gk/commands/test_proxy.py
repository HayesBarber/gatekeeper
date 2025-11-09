from gk.commands import add, proxy, list_
import json


def test_proxy_happy_path(console, console_input, local_base_url, seed_user):
    client_id = "proxy_test_client"
    inputs = [
        local_base_url,
        client_id,
        "x-client-id",
        "x-api-key",
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

    # Proxy GET /echo
    args = type("Args", (), {})()
    args.method = "GET"
    args.path = "echo"
    args.instance = None
    args.body = None
    proxy.handle(args, console)
    output = console.export_text()
    data = json.loads(output)
    assert data["method"] == "GET"
    assert data["path"] == "/echo"
    assert "user-agent" in data["headers"]

    # Proxy POST /echo
    args = type("Args", (), {})()
    args.method = "POST"
    args.path = "echo"
    args.instance = None
    args.body = json.dumps({"msg": "hi"})
    proxy.handle(args, console)
    output = console.export_text()
    data = json.loads(output)
    assert data["method"] == "POST"
    assert data["body"] == {"msg": "hi"}
    assert "user-agent" in data["headers"]
