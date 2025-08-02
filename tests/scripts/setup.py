import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../../")))

from app.utils.redis_client import redis_client, Namespace
from curveauth.keys import ECCKeyPair
import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from multiprocessing import Process
import json
import base64
from pathlib import Path

def seed_redis():
    client_id = "Test_User"
    keypair = ECCKeyPair.generate()
    public_key = keypair.public_key_raw_base64()

    redis_client.set(Namespace.USERS, client_id, public_key)

    test_data = {
        "client_id": client_id,
        "private_key": base64.b64encode(keypair.private_pem()).decode("utf-8"),
        "public_key": public_key,
    }

    data_path = Path(__file__).parent.parent / "seeded_user.json"
    data_path.write_text(json.dumps(test_data))

    return client_id, keypair

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
    from app.config import settings
    settings.blacklisted_paths = ["/proxy/blocked", "/blocked"]
    settings.required_headers = {
        "User-Agent": "test-user-agent",
    }
    settings.upstream_base_url = "http://127.0.0.1:8080"
    settings.proxy_path = "/proxy"

    from app.main import app
    config = uvicorn.Config(app, host="127.0.0.1", port=8000, log_level="info")
    server = uvicorn.Server(config)
    server.run()

if __name__ == "__main__":
    seed_redis()

    upstream_proc = Process(target=run_dummy_upstream)
    app_proc = Process(target=start_app)

    print("Services starting...")

    upstream_proc.start()
    app_proc.start()

    print("Ready. Run tests with pytest")

    try:
        upstream_proc.join()
        app_proc.join()
    except KeyboardInterrupt:
        print("Shutting down...")
        upstream_proc.terminate()
        app_proc.terminate()
