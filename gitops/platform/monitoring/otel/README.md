# OpenTelemetry Collector

Helm chart **0.95.0** — deployment mode collector with OTLP gRPC/HTTP receivers and **10%** probabilistic trace sampling.

- Live config: `values.yaml` (`config` block)
- Reference copy: `collector-config.yaml`

Traces export to `debug` exporter in lab (no Tempo/Jaeger backend in v1).

Instrument Boutique services by setting `OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.monitoring.svc:4318` (future enhancement).
