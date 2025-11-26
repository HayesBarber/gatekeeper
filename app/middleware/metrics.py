import time
from fastapi import Request, Response
from app.utils.otel import otel


async def metrics_middleware(request: Request, call_next):
    start_time = time.time()

    response: Response = await call_next(request)

    duration_ms = (time.time() - start_time) * 1000
    method = request.method
    path = request.url.path
    status_code = response.status_code

    if getattr(request.state, "gateway_reject", False):
        outcome = "gateway_reject"
    elif (
        getattr(request.state, "upstream_status", None)
        and 400 <= request.state.upstream_status < 600
    ):
        outcome = "upstream_error"
    else:
        outcome = "success"

    # Record metrics
    otel.requests_total.add(
        1,
        labels={
            "method": method,
            "path": path,
            "status_code": str(status_code),
            "outcome": outcome,
        },
    )

    otel.request_duration.record(
        duration_ms, labels={"method": method, "path": path, "outcome": outcome}
    )

    return response
