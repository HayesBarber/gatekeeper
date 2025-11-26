from fastapi import FastAPI
from app.controllers import api_router
from app.middleware import (
    required_headers_middleware,
    proxy_middleware,
    blacklist_middleware,
    metrics_middleware,
)

app = FastAPI(title="Gate Keeper")
app.middleware("http")(metrics_middleware)
app.middleware("http")(proxy_middleware)
app.middleware("http")(required_headers_middleware)
app.middleware("http")(blacklist_middleware)
app.include_router(api_router)
