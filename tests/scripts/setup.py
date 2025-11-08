import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../../")))

import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from multiprocessing import Process


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
    from app.config import settings

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

    from app.main import app

    config = uvicorn.Config(app, host="127.0.0.1", port=8000, log_level="info")
    server = uvicorn.Server(config)
    server.run()


if __name__ == "__main__":
    upstream1 = Process(target=run_dummy_upstream, args=(8080,))
    upstream2 = Process(target=run_dummy_upstream, args=(8081,))
    app_proc = Process(target=start_app)

    print("Services starting...")

    upstream1.start()
    upstream2.start()
    app_proc.start()

    print("Ready. Run tests with pytest")

    try:
        upstream1.join()
        upstream2.join()
        app_proc.join()
    except KeyboardInterrupt:
        print("Shutting down...")
        upstream1.terminate()
        upstream2.terminate()
        app_proc.terminate()
