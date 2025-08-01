from fastapi import Request
from starlette.responses import JSONResponse
from app.config import settings
from app.utils.logger import LOGGER

async def required_headers_middleware(request: Request, call_next):
    LOGGER.info(f"[RequiredHeaders] Checking headers for {request.method} {request.url.path}")

    missing = [
        header for header in settings.required_headers
        if header.lower() not in request.headers
    ]

    if missing:
        LOGGER.warn(f"Request missing required headers: {missing}")
        return JSONResponse(
            status_code=400,
            content={"detail": "Missing required headers"},
        )

    return await call_next(request)
