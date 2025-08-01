from fastapi import Request
from fastapi.responses import JSONResponse
from app.utils.logger import LOGGER
from app.config import settings

async def proxy_middleware(request: Request, call_next):
    LOGGER.info(f"[Proxy] Checking for proxy eligibility for {request.method} {request.url.path}")

    if not request.url.path.startswith(settings.proxy_path):
        return await call_next(request)

    api_key = request.headers.get(settings.api_key_header)
    if not api_key:
        LOGGER.warn(f"[Proxy] Missing API key for {request.method} {request.url.path}")
        return JSONResponse(status_code=403, content={"detail": "Missing required headers"})

    LOGGER.info(f"[Proxy] Forwarding request {request.method} {request.url.path}")
    return await call_next(request)
