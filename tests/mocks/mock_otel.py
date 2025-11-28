class MockMetric:
    def __init__(self, name=""):
        self.name = name
        self.calls = []

    def add(self, amount: int, attributes: dict | None = None):
        self.calls.append(("add", amount, attributes or {}))

    def record(self, value: float, attributes: dict | None = None):
        self.calls.append(("record", value, attributes or {}))


class MockOtel:
    def __init__(self):
        self.requests_total = MockMetric("gateway.requests_total")
        self.request_duration = MockMetric("gateway.request_duration_ms")
