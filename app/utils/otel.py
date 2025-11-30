from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry import metrics
from app.config import settings


class Otel:
    def __init__(self, service_name: str = "gatekeeper"):
        self.service_name = service_name

        resource = Resource.create({"service.name": self.service_name})

        exporter = OTLPMetricExporter()

        metric_readers = []
        if settings.otel_enabled:
            metric_readers.append(PeriodicExportingMetricReader(exporter))

        provider = MeterProvider(
            resource=resource,
            metric_readers=metric_readers,
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

        self.challenges_created = self.meter.create_counter(
            name="gateway.challenges_created",
            description="Challenges issued",
            unit="1",
        )

        self.challenge_verification_attempts = self.meter.create_counter(
            name="gateway.challenge_verification_attempts",
            description="Verification attempts",
            unit="1",
        )

        self.challenge_verification_failures = self.meter.create_counter(
            name="gateway.challenge_verification_failures",
            description="Verification failures",
            unit="1",
        )

        self.api_keys_issued = self.meter.create_counter(
            name="gateway.api_keys_issued",
            description="API keys successfully issued",
            unit="1",
        )


otel = Otel()
