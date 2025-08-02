from fastapi import Request
from starlette.responses import JSONResponse
from app.config import settings
from app.utils.logger import LOGGER

async def required_headers_middleware(request: Request, call_next):
    LOGGER.info(f"[RequiredHeaders] Checking headers for {request.method} {request.url.path}")

    missing = []
    for header, expected in settings.required_headers.items():
        header_value = request.headers.get(header.lower())
        if header_value is None or (expected is not None and header_value != expected):
            missing.append(header)

    if missing:
        LOGGER.warn(f"Request missing or mismatched required headers: {missing}")
        return JSONResponse(
            status_code=400,
            content={"detail": "Missing required headers"},
        )

    return await call_next(request)
