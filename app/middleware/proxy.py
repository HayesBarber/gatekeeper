from fastapi import Request
from app.utils.logger import LOGGER

async def proxy_middleware(request: Request, call_next):
    LOGGER.info(f"[Proxy] Validating request {request.method} {request.url.path}")