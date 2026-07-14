# Monitoring platform

kube-prometheus-stack (chart **58.2.2**), Grafana dashboards, PrometheusRules, ServiceMonitors, and OpenTelemetry Collector (chart **0.95.0**).

## Components

| Path | Purpose |
|------|---------|
| `kube-prometheus-stack/` | Prometheus, Grafana, Alertmanager Helm app |
| `otel/` | OTLP collector baseline (10% trace sampling) |
| `dashboards/` | Cluster + Boutique Grafana dashboards |

## Hostname

`grafana-boutique.biroltilki.art` — TLS via cert-manager DNS-01.

## Prerequisites

- Topic 06 ingress + cert-manager
- Topic 10 Boutique dev running (dashboards/alerts reference `boutique-dev`)
- Grafana admin Secret (Topic 11 setup guide)

## Usage

[docs/setup/11-observability.md](../../../docs/setup/11-observability.md)
