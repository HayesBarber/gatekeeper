import os
import stat
from gk import storage
from gk.models.gk_keypair import GkKeyPair, GkKeyPairs
from gk.models.gk_instance import GkInstance, GkInstances


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

    with open(filepath, "rb") as f:
        content = f.read()
    assert b"testing" not in content
    assert b"test_public_key" not in content
    assert b"test_private_key" not in content

    mode = os.stat(filepath).st_mode
    assert stat.S_IMODE(mode) == 0o600

    loaded: GkKeyPairs = storage.load_model(storage.StorageKey.KEYPAIRS)
    assert len(loaded.keypairs) == 1
    assert loaded.keypairs[0].instance_base_url == "testing"
    assert loaded.keypairs[0].public_key == b"test_public_key"
    assert loaded.keypairs[0].private_key == b"test_private_key"


def test_save_and_load_nonsecure_model(tmp_path):
    instance = GkInstance(
        base_url="http://two.com",
        client_id="test2",
        active=True,
    )
    model = GkInstances(instances=[instance])
    storage.save_model(storage.StorageKey.INSTANCES, model)
    filepath = tmp_path / f".gk/{storage.FILE_NAMES[storage.StorageKey.INSTANCES]}"
    assert filepath.exists()

    mode = os.stat(filepath).st_mode
    assert stat.S_IMODE(mode) == 0o600

    loaded: GkInstances = storage.load_model(storage.StorageKey.INSTANCES)
    assert len(loaded.instances) == 1
    assert loaded.instances[0].base_url == "http://two.com"
    assert loaded.instances[0].client_id == "test2"
    assert loaded.instances[0].active


def test_ensure_data_dir_permissions(tmp_path):
    test_dir = tmp_path / ".gk"
    storage.ensure_data_dir()
    assert test_dir.exists()
    mode = os.stat(test_dir).st_mode
    assert stat.S_IMODE(mode) == 0o700
