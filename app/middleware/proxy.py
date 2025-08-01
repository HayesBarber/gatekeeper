from fastapi import Request
from app.utils.logger import LOGGER

async def proxy_middleware(request: Request, call_next):
    LOGGER.info(f"[Proxy] Checking for proxy eligibility for {request.method} {request.url.path}")
    return await call_next(request)
