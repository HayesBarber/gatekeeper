import requests
import pytest
from fastapi import Response
from unittest.mock import AsyncMock
from app.middleware.required_headers import required_headers_middleware
from starlette.responses import JSONResponse
from app.config import settings


def test_missing_required_headers():
    url = "http://localhost:8000/anything"
    response = requests.get(url)
    assert response.status_code == 400
    assert response.json()["detail"] == "Missing required headers"


@pytest.mark.anyio
async def test_required_headers_sets_state(make_request):
    settings.required_headers = {"test_header": "test_value"}

    request = make_request()
    call_next = AsyncMock(return_value=Response(status_code=200))
    response = await required_headers_middleware(request, call_next)

    assert isinstance(response, JSONResponse)
    assert response.status_code == 400
    assert getattr(request.state, "gateway_reject") is True
    assert getattr(request.state, "reject_reason") == "required_headers"
    call_next.assert_not_called()


@pytest.mark.anyio
async def test_required_headers_allows_request(make_request):
    settings.required_headers = {}

    request = make_request()
    call_next = AsyncMock(return_value=Response(status_code=200))
    response = await required_headers_middleware(request, call_next)

    assert response.status_code == 200
    call_next.assert_called_once()
    assert not hasattr(request.state, "gateway_reject")
    assert not hasattr(request.state, "reject_reason")
