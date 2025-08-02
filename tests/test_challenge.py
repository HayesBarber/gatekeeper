from tests.scripts.setup import load_seeded_user
from pathlib import Path

def test_generate_challenge():
    client_id, keypair = load_seeded_user(Path(__file__).parent / "generated/seeded_user.json")
    assert client_id == "Test_User"
