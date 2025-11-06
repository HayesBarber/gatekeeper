import requests


def test_blacklist_blocked_with_proxy():
    url = "http://localhost:8000/proxy/blocked"
    response = requests.get(url)
    assert response.status_code == 403
    assert response.json()["detail"] == "Access to this path is forbidden."


def test_blacklist_blocked():
    url = "http://localhost:8000/blocked"
    response = requests.get(url)
    assert response.status_code == 403
    assert response.json()["detail"] == "Access to this path is forbidden."
