import requests
from tests.scripts.setup import load_seeded_user
from pathlib import Path
from curveauth.signatures import sign_message


def test_challenge_flow():
    client_id, keypair = load_seeded_user(
        Path(__file__).parent / "generated/seeded_user.json"
    )

    resp = requests.post(
        "http://localhost:8000/challenge",
        json={"client_id": client_id},
        headers={"User-Agent": "test-user-agent"},
    )
    assert resp.status_code == 200
    challenge = resp.json()["challenge"]
    challenge_id = resp.json()["challenge_id"]

    signature = sign_message(challenge, keypair.private_pem().decode("utf-8"))

    verify_resp = requests.post(
        "http://localhost:8000/challenge/verify",
        json={
            "client_id": client_id,
            "challenge_id": challenge_id,
            "signature": signature,
        },
        headers={"User-Agent": "test-user-agent"},
    )
    assert verify_resp.status_code == 200
    api_key = verify_resp.json()["api_key"]
    assert api_key

    proxy_resp = requests.get(
        "http://localhost:8000/proxy/echo",
        headers={
            "x-api-key": api_key,
            "x-requestor-id": client_id,
            "User-Agent": "test-user-agent",
        },
    )
    assert proxy_resp.status_code == 200
    assert proxy_resp.json()["path"] == "/echo"


def test_verify_challenge_invalid_signature():
    client_id, _ = load_seeded_user(
        Path(__file__).parent / "generated/seeded_user.json"
    )

    resp = requests.post(
        "http://localhost:8000/challenge",
        json={"client_id": client_id},
        headers={"User-Agent": "test-user-agent"},
    )
    assert resp.status_code == 200
    challenge_id = resp.json()["challenge_id"]

    invalid_signature = "invalid_signature"

    verify_resp = requests.post(
        "http://localhost:8000/challenge/verify",
        json={
            "client_id": client_id,
            "challenge_id": challenge_id,
            "signature": invalid_signature,
        },
        headers={"User-Agent": "test-user-agent"},
    )
    assert verify_resp.status_code == 403


def test_proxy_request_missing_api_key():
    client_id, _ = load_seeded_user(
        Path(__file__).parent / "generated/seeded_user.json"
    )

    proxy_resp = requests.get(
        "http://localhost:8000/proxy/echo",
        headers={
            "x-requestor-id": client_id,
            "User-Agent": "test-user-agent",
        },
    )
    assert proxy_resp.status_code == 403
