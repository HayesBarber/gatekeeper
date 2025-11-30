import pytest
from unittest.mock import AsyncMock
from app.middleware.proxy import proxy_middleware
from starlette.responses import JSONResponse
from app.config import Settings, settings
from app.utils.redis_client import redis_client
from datetime import datetime, timezone, timedelta
import httpx


@pytest.mark.anyio
async def test_proxy_missing_client_id(make_request):
    request = make_request(
        "/proxy/test",
        headers={
            settings.api_key_header: "abc123",
        },
    )

    call_next = AsyncMock()

    resp = await proxy_middleware(request, call_next)

    assert isinstance(resp, JSONResponse)
    assert resp.status_code == 403

    assert request.state.gateway_reject is True
    assert request.state.reject_reason == "missing_client_id"

    call_next.assert_not_called()


@pytest.mark.anyio
async def test_proxy_unknown_client(monkeypatch, make_request):
    monkeypatch.setattr(redis_client, "get_model", lambda *a, **k: None)

    request = make_request(
        "/proxy/test",
        headers={
            settings.client_id_header: "abc",
            settings.api_key_header: "correct-key",
        },
    )

    call_next = AsyncMock()

    resp = await proxy_middleware(request, call_next)

    assert resp.status_code == 403
    assert request.state.gateway_reject
    assert request.state.reject_reason == "unknown_client"


class FakeStored:
    def __init__(
        self,
        value="expected-key",
        expires_at=datetime.now(timezone.utc) + timedelta(hours=1),
    ):
        self.api_key = value
        self.expires_at = expires_at


@pytest.mark.anyio
async def test_proxy_invalid_api_key(monkeypatch, make_request):
    monkeypatch.setattr(redis_client, "get_model", lambda *a, **k: FakeStored())

    request = make_request(
        "/proxy/x",
        headers={
            settings.client_id_header: "abc",
            settings.api_key_header: "wrong-key",
        },
    )

    resp = await proxy_middleware(request, AsyncMock())

    assert resp.status_code == 403
    assert request.state.reject_reason == "invalid_api_key"


@pytest.mark.anyio
async def test_proxy_no_upstream(monkeypatch, make_request):
    monkeypatch.setattr(
        redis_client, "get_model", lambda *a, **k: FakeStored(value="a")
    )

    request = make_request(
        "/proxy/x",
        headers={
            settings.client_id_header: "abc",
            settings.api_key_header: "a",
        },
    )

    resp = await proxy_middleware(request, AsyncMock())

    assert resp.status_code == 502
    assert request.state.reject_reason == "no_upstream"


class FakeResponse:
    def __init__(self, status_code=500, body=b"err"):
        self.status_code = status_code
        self.content = body
        self.headers = {"content-type": "text/plain"}


@pytest.mark.anyio
async def test_proxy_upstream_error(monkeypatch, make_request):
    monkeypatch.setattr(
        redis_client, "get_model", lambda *a, **k: FakeStored(value="a")
    )
    monkeypatch.setattr(
        Settings, "resolve_upstream", lambda *a, **k: ("http://x", "/y")
    )

    async def fake_request(*args, **kwargs):
        return FakeResponse(500, b"upstream error")

    monkeypatch.setattr(httpx.AsyncClient, "request", fake_request)

    request = make_request(
        "/proxy/z",
        headers={
            settings.client_id_header: "abc",
            settings.api_key_header: "a",
        },
    )

    resp = await proxy_middleware(request, AsyncMock())

    assert resp.status_code == 500
    assert request.state.upstream_status == 500
