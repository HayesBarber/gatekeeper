import pytest
from curveauth.keys import ECCKeyPair
from app.utils.redis_client import redis_client, Namespace
import multiprocessing
import time
import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from app.config import settings
from app.main import app
import requests


@pytest.fixture()
def seeded_user():
    client_id = "Test_User"
    keypair = ECCKeyPair.generate()
    public_key = keypair.public_key_raw_base64()

    redis_client.set(Namespace.USERS, client_id, public_key)

    return client_id, keypair


@pytest.fixture()
def seed_user():

    def _seed(client_id, public_key):
        redis_client.set(Namespace.USERS, client_id, public_key)

    return _seed


@pytest.fixture
def local_base_url():
    return "http://127.0.0.1:8000"


def create_dummy_upstream_app() -> FastAPI:
    app = FastAPI()

    @app.get("/echo")
    async def echo_get(request: Request):
        return JSONResponse(
            {
                "method": "GET",
                "headers": dict(request.headers),
                "path": str(request.url.path),
            }
        )

    @app.post("/echo")
    async def echo_post(request: Request):
        body = await request.json()
        return JSONResponse(
            {
                "method": "POST",
                "headers": dict(request.headers),
                "body": body,
            }
        )

    return app


def run_dummy_upstream(port: int = 8080):
    app = create_dummy_upstream_app()
    config = uvicorn.Config(app, host="127.0.0.1", port=port, log_level="info")
    server = uvicorn.Server(config)
    server.run()


def start_app():
    settings.blacklisted_paths = {
        "/proxy/blocked": [],
        "/blocked": [],
    }
    settings.required_headers = {
        "User-Agent": "test-user-agent",
    }
    settings.upstreams = {
        "/api1": "http://127.0.0.1:8080",
        "/api2": "http://127.0.0.1:8081",
    }
    settings.proxy_path = "/proxy"

    config = uvicorn.Config(app, host="127.0.0.1", port=8000, log_level="info")
    server = uvicorn.Server(config)
    server.run()


@pytest.fixture(scope="session", autouse=True)
def gatekeeper_services():
    """Start Gatekeeper app and dummy upstreams before tests, then tear them down after."""
    upstream1 = multiprocessing.Process(target=run_dummy_upstream, args=(8080,))
    upstream2 = multiprocessing.Process(target=run_dummy_upstream, args=(8081,))
    app_proc = multiprocessing.Process(target=start_app)

    upstream1.start()
    upstream2.start()
    app_proc.start()

    ports = [8080, 8081, 8000]
    for port in ports:
        url = f"http://127.0.0.1:{port}/"
        for _ in range(20):
            try:
                r = requests.get(url, timeout=0.5)
                # gatekeeper will return 400 here for missing headers
                if r.status_code in (200, 400, 404, 405):
                    break
            except Exception:
                pass
            time.sleep(0.5)
        else:
            pytest.fail(f"Service on port {port} did not start in time")

    yield

    # Teardown
    for proc in [upstream1, upstream2, app_proc]:
        proc.terminate()
        proc.join(timeout=5)
