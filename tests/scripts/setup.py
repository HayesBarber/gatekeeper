from app.utils.redis_client import redis_client, Namespace
from curveauth.keys import ECCKeyPair
import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

def seed_redis():
    client_id = "Test_User"
    keypair = ECCKeyPair.generate()
    public_key = keypair.public_key_raw_base64()

    redis_client.set(Namespace.USERS, client_id, public_key)

    return (client_id, keypair)

def create_dummy_upstream_app() -> FastAPI:
    app = FastAPI()

    @app.get("/echo")
    async def echo_get(request: Request):
        return JSONResponse({
            "method": "GET",
            "headers": dict(request.headers),
            "path": str(request.url.path),
        })

    @app.post("/echo")
    async def echo_post(request: Request):
        body = await request.json()
        return JSONResponse({
            "method": "POST",
            "headers": dict(request.headers),
            "body": body,
        })

    return app

def run_dummy_upstream():
    app = create_dummy_upstream_app()
    config = uvicorn.Config(app, host="127.0.0.1", port=8080, log_level="info")
    server = uvicorn.Server(config)
    server.run()

def start_app():
    pass