import pytest
from pathlib import Path
import json
import base64
from curveauth.keys import ECCKeyPair


@pytest.fixture(scope="session")
def seeded_user():
    """
    Load the seeded test user created by tests/scripts/setup.py.

    Returns:
        Tuple[str, curveauth.keys.ECCKeyPair]: (client_id, keypair)
    Raises:
        FileNotFoundError: if the generated/seeded_user.json file is missing.
    """
    data_path = Path(__file__).parent / "generated" / "seeded_user.json"
    if not data_path.exists():
        raise FileNotFoundError(
            f"{data_path} not found. Run tests/scripts/setup.py to seed redis and create the file "
            "(e.g. `python tests/scripts/setup.py`)."
        )

    loaded = json.loads(data_path.read_text())

    client_id = loaded["client_id"]
    private_pem = base64.b64decode(loaded["private_key"])

    keypair = ECCKeyPair.load_private_pem(private_pem)

    return client_id, keypair


@pytest.fixture
def local_base_url():
    return "http://localhost:8000"
