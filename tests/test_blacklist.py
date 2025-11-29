import requests
import pytest
from fastapi import Response
from unittest.mock import AsyncMock
from app.middleware.blacklist import blacklist_middleware
from starlette.responses import JSONResponse
from app.config import settings


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


@pytest.mark.anyio
async def test_blacklist_sets_state(monkeypatch, make_request):
    monkeypatch.setattr(
        settings,
        "blacklisted_paths",
        {"/blocked": ["GET"]},
    )

    request = make_request("/blocked", "GET")
    call_next = AsyncMock(return_value=Response(status_code=200))
    response = await blacklist_middleware(request, call_next)

    assert isinstance(response, JSONResponse)
    assert response.status_code == 403
    assert getattr(request.state, "gateway_reject") is True
    assert getattr(request.state, "reject_reason") == "blacklist"
    call_next.assert_not_called()


@pytest.mark.anyio
async def test_blacklist_allows_request(monkeypatch, make_request):
    monkeypatch.setattr(
        settings,
        "blacklisted_paths",
        {},
    )

    request = make_request("/not-blocked", "GET")
    call_next = AsyncMock(return_value=Response(status_code=200))

    response = await blacklist_middleware(request, call_next)

    assert response.status_code == 200
    call_next.assert_called_once()

    assert not hasattr(request.state, "gateway_reject")
    assert not hasattr(request.state, "reject_reason")
