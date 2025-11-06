import requests


def test_missing_required_headers():
    url = "http://localhost:8000/anything"
    response = requests.get(url)
    assert response.status_code == 400
    assert response.json()["detail"] == "Missing required headers"
