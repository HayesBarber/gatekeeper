from fastapi import Request
from fastapi.responses import JSONResponse, Response
from app.utils.logger import LOGGER
from app.config import settings
from app.utils.redis_client import redis_client, Namespace
from app.models import ChallengeVerificationResponse
import httpx
from datetime import datetime, timezone


async def proxy_middleware(request: Request, call_next):
    LOGGER.info(
        f"[Proxy] Checking for proxy eligibility for {request.method} {request.url.path}"
    )

    if not request.url.path.startswith(settings.proxy_path):
        return await call_next(request)

    LOGGER.info(f"[Proxy] Validating request {request.method} {request.url.path}")

    client_id = request.headers.get(settings.client_id_header)
    if not client_id:
        LOGGER.warn(
            f"[Proxy] Missing client ID for {request.method} {request.url.path}"
        )
        return JSONResponse(
            status_code=403, content={"detail": "Missing required headers"}
        )

    api_key = request.headers.get(settings.api_key_header)
    if not api_key:
        LOGGER.warn(f"[Proxy] Missing API key for {request.method} {request.url.path}")
        return JSONResponse(
            status_code=403, content={"detail": "Missing required headers"}
        )

    stored = redis_client.get_model(
        Namespace.API_KEYS, client_id, ChallengeVerificationResponse
    )
    if not stored:
        LOGGER.warn(f"[Proxy] No API key found for client {client_id}")
        return JSONResponse(status_code=403, content={"detail": "Forbidden"})

    if stored.api_key != api_key:
        LOGGER.warn(f"[Proxy] Invalid API key for client {client_id}")
        return JSONResponse(status_code=403, content={"detail": "Forbidden"})

    if stored.expires_at < datetime.now(timezone.utc):
        LOGGER.warn(f"[Proxy] API key expired for client {client_id}")
        return JSONResponse(status_code=403, content={"detail": "Forbidden"})

    LOGGER.info(f"[Proxy] Authorized request for client {client_id}, forwarding")

    async with httpx.AsyncClient() as client:
        forward_url = f"{settings.upstream_base_url}{request.url.path.removeprefix(settings.proxy_path)}"
        headers = dict(request.headers)
        headers.pop("host", None)
        try:
            proxy_response = await client.request(
                method=request.method,
                url=forward_url,
                headers=headers,
                content=await request.body(),
                follow_redirects=True,
            )
            return Response(
                status_code=proxy_response.status_code,
                content=proxy_response.content,
                headers=dict(proxy_response.headers),
                media_type=proxy_response.headers.get("content-type"),
            )
        except httpx.RequestError as e:
            LOGGER.error(f"[Proxy] Error forwarding request: {e}")
            return JSONResponse(status_code=502, content={"detail": "Bad gateway"})
