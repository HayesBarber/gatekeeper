import requests
from curveauth.signatures import sign_message


def test_challenge_flow(seeded_user, local_base_url):
    client_id, keypair = seeded_user

    resp = requests.post(
        f"{local_base_url}/challenge",
        json={"client_id": client_id},
        headers={"User-Agent": "test-user-agent"},
    )
    assert resp.status_code == 200
    challenge = resp.json()["challenge"]
    challenge_id = resp.json()["challenge_id"]

    signature = sign_message(challenge, keypair.private_pem().decode("utf-8"))

    verify_resp = requests.post(
        f"{local_base_url}/challenge/verify",
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

    for i in range(1, 3):
        proxy_resp = requests.get(
            f"{local_base_url}/proxy/api{i}/echo",
            headers={
                "x-api-key": api_key,
                "x-requestor-id": client_id,
                "User-Agent": "test-user-agent",
            },
        )
        assert proxy_resp.status_code == 200
        assert proxy_resp.json()["path"] == "/echo"


def test_verify_challenge_invalid_signature(seeded_user, local_base_url):
    client_id, _ = seeded_user

    resp = requests.post(
        f"{local_base_url}/challenge",
        json={"client_id": client_id},
        headers={"User-Agent": "test-user-agent"},
    )
    assert resp.status_code == 200
    challenge_id = resp.json()["challenge_id"]

    invalid_signature = "invalid_signature"

    verify_resp = requests.post(
        f"{local_base_url}/challenge/verify",
        json={
            "client_id": client_id,
            "challenge_id": challenge_id,
            "signature": invalid_signature,
        },
        headers={"User-Agent": "test-user-agent"},
    )
    assert verify_resp.status_code == 403


def test_proxy_request_missing_api_key(seeded_user, local_base_url):
    client_id, _ = seeded_user

    proxy_resp = requests.get(
        f"{local_base_url}/proxy/echo",
        headers={
            "x-requestor-id": client_id,
            "User-Agent": "test-user-agent",
        },
    )
    assert proxy_resp.status_code == 403
