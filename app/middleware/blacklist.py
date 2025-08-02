from fastapi import Request
from starlette.responses import JSONResponse
from app.config import settings
from app.utils.logger import LOGGER

async def blacklist_middleware(request: Request, call_next):
    request_path = request.url.path

    if request_path in settings.blacklisted_paths:
        LOGGER.info(f"Blocked request to blacklisted path: {request_path}")
        return JSONResponse(status_code=403, content={"detail": "Access to this path is forbidden."})

    return await call_next(request)
