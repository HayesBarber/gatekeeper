from fastapi import Request
from fastapi.responses import JSONResponse, Response
from app.utils.logger import LOGGER
from app.config import settings
from app.utils.redis_client import redis_client, Namespace
from app.models import ChallengeVerificationResponse
import httpx
from datetime import datetime, timezone


def reject(request: Request, reason: str, status: int, detail: str):
    request.state.gateway_reject = True
    request.state.reject_reason = reason
    return JSONResponse(status_code=status, content={"detail": detail})


def get_required_headers(request: Request):
    client_id = request.headers.get(settings.client_id_header)
    api_key = request.headers.get(settings.api_key_header)
    return client_id, api_key


def validate_headers(request: Request):
    client_id, api_key = get_required_headers(request)

    if not client_id:
        LOGGER.warn("[Proxy] Missing client ID")
        return reject(request, "missing_client_id", 403, "Missing required headers")

    if not api_key:
        LOGGER.warn("[Proxy] Missing API key")
        return reject(request, "missing_api_key", 403, "Missing required headers")

    return client_id, api_key


def validate_api_key(request: Request, client_id: str, api_key: str):
    stored = redis_client.get_model(
        Namespace.API_KEYS, client_id, ChallengeVerificationResponse
    )

    if not stored:
        LOGGER.warn(f"[Proxy] No API key for client {client_id}")
        return reject(request, "no_api_key_for_client", 403, "Forbidden")

    if stored.api_key != api_key:
        LOGGER.warn(f"[Proxy] Invalid API key for client {client_id}")
        return reject(request, "invalid_api_key", 403, "Forbidden")

    if stored.expires_at < datetime.now(timezone.utc):
        LOGGER.warn(f"[Proxy] API key expired for client {client_id}")
        return reject(request, "api_key_expired", 403, "Forbidden")

    return None


def resolve_forward_url(request: Request):
    rel_path = request.url.path.removeprefix(settings.proxy_path)
    resolved = settings.resolve_upstream(rel_path)

    if not resolved:
        LOGGER.warn(f"[Proxy] No upstream for {rel_path}")
        return None

    base, trimmed_path = resolved
    return f"{base}{trimmed_path}"


async def forward_request(request: Request, url: str):
    headers = dict(request.headers)
    headers.pop("host", None)

    async with httpx.AsyncClient() as client:
        try:
            resp = await client.request(
                method=request.method,
                url=url,
                headers=headers,
                content=await request.body(),
                follow_redirects=True,
            )

            if 400 <= resp.status_code < 600:
                request.state.upstream_status = resp.status_code

            return Response(
                status_code=resp.status_code,
                content=resp.content,
                headers=dict(resp.headers),
                media_type=resp.headers.get("content-type"),
            )

        except httpx.RequestError as e:
            LOGGER.error(f"[Proxy] Forwarding error: {e}")
            request.state.upstream_status = 502
            return JSONResponse(status_code=502, content={"detail": "Bad gateway"})


async def proxy_middleware(request: Request, call_next):
    LOGGER.info(
        f"[Proxy] Checking for proxy eligibility for {request.method} {request.url.path}"
    )

    if not request.url.path.startswith(settings.proxy_path):
        return await call_next(request)

    headers_result = validate_headers(request)
    if isinstance(headers_result, JSONResponse):
        return headers_result

    client_id, api_key = headers_result

    key_error = validate_api_key(request, client_id, api_key)
    if key_error:
        return key_error

    forward_url = resolve_forward_url(request)
    if not forward_url:
        return reject(request, "no_upstream", 502, "No upstream configured")

    LOGGER.info(f"[Proxy] Forwarding to {forward_url}")
    return await forward_request(request, forward_url)
