import pytest
from unittest.mock import AsyncMock
from app.middleware.proxy import proxy_middleware
from starlette.responses import JSONResponse
from app.config import settings


@pytest.mark.anyio
async def test_proxy_missing_client_id(make_request):
    settings.proxy_path = "/proxy"

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
