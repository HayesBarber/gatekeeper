from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry import metrics


class Otel:
    def __init__(self, service_name: str = "gatekeeper"):
        self.service_name = service_name

        resource = Resource.create({"service.name": self.service_name})

        exporter = OTLPMetricExporter()

        reader = PeriodicExportingMetricReader(exporter)

        provider = MeterProvider(
            resource=resource,
            metric_readers=[reader],
        )

        metrics.set_meter_provider(provider)
        self.meter = metrics.get_meter(self.service_name)

        self.requests_total = self.meter.create_counter(
            name="gateway.requests_total",
            description="Total number of requests processed by the gateway",
            unit="1",
        )

        self.request_duration = self.meter.create_histogram(
            name="gateway.request_duration_ms",
            description="Request duration in milliseconds",
            unit="ms",
        )


otel = Otel()
