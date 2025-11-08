from gk.commands import keygen


def test_keygen(console):
    args = type("Args", (), {})()
    keygen.handle(args, console)

    output = console.export_text()
    assert "public_key" in output
    assert "private_key" in output
