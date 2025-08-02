import requests

def test_blacklist_blocked():
    url = "http://localhost:8000/proxy/blocked"
    response = requests.get(url)
    print("Status Code:", response.status_code)
    print("Response Body:", response.json())
    assert response.status_code == 403
    assert response.json()["detail"] == "Access to this path is forbidden."
