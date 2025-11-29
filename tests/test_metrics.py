import pytest
from fastapi import Request
from unittest.mock import AsyncMock
from fastapi import Response
from app.middleware.metrics import metrics_middleware
from tests.mocks.mock_otel import MockOtel


@pytest.fixture
def mock_otel(monkeypatch):
    otel = MockOtel()
    monkeypatch.setattr("app.middleware.metrics.otel", otel)
    return otel


def make_request(path="/x", method="GET"):
    scope = {
        "type": "http",
        "method": method,
        "path": path,
        "headers": [],
        "query_string": b"",
        "server": ("testserver", 80),
        "client": ("testclient", 50000),
    }
    return Request(scope)


@pytest.mark.anyio
async def test_metrics_success(mock_otel):
    request = make_request()
    call_next = AsyncMock(return_value=Response(status_code=200))

    await metrics_middleware(request, call_next)

    opname, amount, attrs = mock_otel.requests_total.calls[0]
    assert opname == "add"
    assert amount == 1
    assert attrs["outcome"] == "success"
    assert attrs["status_code"] == "200"


@pytest.mark.anyio
async def test_metrics_gateway_reject(mock_otel):
    request = make_request()
    request.state.gateway_reject = True
    request.state.reject_reason = "bad_key"

    call_next = AsyncMock(return_value=Response(status_code=403))
    await metrics_middleware(request, call_next)

    opname, amount, attrs = mock_otel.requests_total.calls[0]
    assert opname == "add"
    assert amount == 1
    assert attrs["outcome"] == "gateway_reject:bad_key"
    assert attrs["status_code"] == "403"
