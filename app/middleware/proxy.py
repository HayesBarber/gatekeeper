from fastapi import Request
from fastapi.responses import JSONResponse
from app.utils.logger import LOGGER
from app.config import settings
from app.utils.redis_client import redis_client, Namespace
from app.models.challenge_verification_response import ChallengeVerificationResponse

async def proxy_middleware(request: Request, call_next):
    LOGGER.info(f"[Proxy] Checking for proxy eligibility for {request.method} {request.url.path}")

    if not request.url.path.startswith(settings.proxy_path):
        return await call_next(request)

    LOGGER.info(f"[Proxy] Validating request {request.method} {request.url.path}")

    client_id = request.headers.get(settings.client_id_header)
    if not client_id:
        LOGGER.warn(f"[Proxy] Missing client ID for {request.method} {request.url.path}")
        return JSONResponse(status_code=403, content={"detail": "Missing required headers"})

    api_key = request.headers.get(settings.api_key_header)
    if not api_key:
        LOGGER.warn(f"[Proxy] Missing API key for {request.method} {request.url.path}")
        return JSONResponse(status_code=403, content={"detail": "Missing required headers"})

    stored = redis_client.get_model(Namespace.API_KEYS, client_id, ChallengeVerificationResponse)
    if not stored:
        LOGGER.warn(f"[Proxy] No API key found for client {client_id}")
        return JSONResponse(status_code=403, content={"detail": "Forbidden"})

    if stored.api_key != api_key:
        LOGGER.warn(f"[Proxy] Invalid API key for client {client_id}")
        return JSONResponse(status_code=403, content={"detail": "Forbidden"})

    LOGGER.info(f"[Proxy] Authorized request for client {client_id}, forwarding")
    return await call_next(request)
