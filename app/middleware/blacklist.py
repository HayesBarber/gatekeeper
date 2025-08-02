from fastapi import Request
from starlette.responses import JSONResponse
from app.config import settings
from app.utils.logger import LOGGER

async def blacklist_middleware(request: Request, call_next):
    request_path = request.url.path
    LOGGER.info(f"[Blacklist] Checking if path is black listed {request_path}")

    if request_path in settings.blacklisted_paths:
        LOGGER.warn(f"Blocking request to blacklisted path: {request_path}")
        return JSONResponse(status_code=403, content={"detail": "Access to this path is forbidden."})

    return await call_next(request)
