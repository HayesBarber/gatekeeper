class MockCounter:
    def __init__(self):
        self.calls = []

    def add(self, amount: int, attributes: dict | None = None):
        self.calls.append(("add", amount, attributes or {}))


class MockHistogram:
    def __init__(self):
        self.calls = []

    def record(self, value: float, attributes: dict | None = None):
        self.calls.append(("record", value, attributes or {}))


class MockOtel:
    def __init__(self):
        self.requests_total = MockCounter()
        self.request_duration = MockHistogram()
