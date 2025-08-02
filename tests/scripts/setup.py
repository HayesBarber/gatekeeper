import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../../")))

from app.utils.redis_client import redis_client, Namespace
from curveauth.keys import ECCKeyPair
import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from app.main import app
from multiprocessing import Process

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
    config = uvicorn.Config(app, host="127.0.0.1", port=8000, log_level="info")
    server = uvicorn.Server(config)
    server.run()

if __name__ == "__main__":
    from time import sleep

    seed_redis()

    upstream_proc = Process(target=run_dummy_upstream)
    app_proc = Process(target=start_app)

    upstream_proc.start()
    app_proc.start()

    print("Services starting...")
    sleep(1)

    print("Ready. Use your scripts to test.")

    try:
        upstream_proc.join()
        app_proc.join()
    except KeyboardInterrupt:
        print("Shutting down...")
        upstream_proc.terminate()
        app_proc.terminate()
