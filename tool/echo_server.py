from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI()


@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE"])
async def echo(request: Request, path: str):
    body = await request.body()

    return JSONResponse(
        {
            "method": request.method,
            "path": "/" + path,
            "query": dict(request.query_params),
            "headers": dict(request.headers),
            "body": body.decode(errors="replace"),
        }
    )
