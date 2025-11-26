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

    outcome = "success"
    reject_reason = getattr(request.state, "reject_reason", None)

    if getattr(request.state, "gateway_reject", False):
        outcome = f"gateway_reject:{reject_reason}"
    elif (
        getattr(request.state, "upstream_status", None)
        and 400 <= request.state.upstream_status < 600
    ):
        outcome = f"upstream_error:{request.state.upstream_status}"

    otel.requests_total.add(
        1,
        attributes={
            "method": method,
            "path": path,
            "status_code": str(status_code),
            "outcome": outcome,
        },
    )

    otel.request_duration.record(
        duration_ms,
        attributes={
            "method": method,
            "path": path,
            "outcome": outcome,
        },
    )

    return response
