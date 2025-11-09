import os
import stat
from gk import storage
from gk.models.gk_keypair import GkKeyPair, GkKeyPairs


def test_save_and_load_encrypted_model(tmp_path):
    keypair: GkKeyPair = GkKeyPair(
        instance_base_url="testing",
        public_key=b"test_public_key",
        private_key=b"test_private_key",
    )
    model = GkKeyPairs(keypairs=[keypair])
    storage.save_model(storage.StorageKey.KEYPAIRS, model)
    filepath = tmp_path / f".gk/{storage.FILE_NAMES[storage.StorageKey.KEYPAIRS]}"
    assert filepath.exists()

    with open(filepath, "r") as f:
        content = f.read()
    assert "testing" not in content
    assert "test_public_key" not in content
    assert "test_private_key" not in content

    mode = os.stat(filepath).st_mode
    assert stat.S_IMODE(mode) == 0o600

    loaded: GkKeyPairs = storage.load_model(storage.StorageKey.KEYPAIRS)
    assert len(loaded.keypairs) == 1
    assert loaded.keypairs[0].instance_base_url == "testing"
    assert loaded.keypairs[0].public_key == b"test_public_key"
    assert loaded.keypairs[0].private_key == b"test_private_key"


# def test_save_and_load_nonsecure_model(tmp_path):
#     storage.save_model(INSTANCES, tmp_path)
#     filepath = tmp_path / f"{INSTANCES}.json"
#     assert filepath.exists()

#     mode = os.stat(filepath).st_mode
#     assert stat.S_IMODE(mode) == 0o600

#     loaded = storage.load_model(INSTANCES, tmp_path)
#     assert loaded == storage.MODELS[INSTANCES]
