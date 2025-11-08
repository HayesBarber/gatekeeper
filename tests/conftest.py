import pytest
from curveauth.keys import ECCKeyPair
from app.utils.redis_client import redis_client, Namespace


@pytest.fixture()
def seeded_user():
    client_id = "Test_User"
    keypair = ECCKeyPair.generate()
    public_key = keypair.public_key_raw_base64()

    redis_client.set(Namespace.USERS, client_id, public_key)

    return client_id, keypair


@pytest.fixture()
def seed_user():

    def _seed(client_id, public_key):
        redis_client.set(Namespace.USERS, client_id, public_key)

    return _seed


@pytest.fixture
def local_base_url():
    return "http://localhost:8000"
