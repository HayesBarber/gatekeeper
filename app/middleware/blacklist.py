from fastapi import Request
from starlette.responses import JSONResponse
from app.config import settings
from app.utils.logger import LOGGER

async def blacklist_middleware(request: Request, call_next):
    pass