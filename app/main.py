from fastapi import FastAPI
from app.controllers import api_router
from app.middleware import required_headers_middleware, proxy_middleware

app = FastAPI(title="Gate Keeper")
app.middleware("http")(proxy_middleware)
app.middleware("http")(required_headers_middleware)
app.include_router(api_router)
