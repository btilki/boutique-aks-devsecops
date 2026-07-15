# Monitoring platform

kube-prometheus-stack (chart **58.2.2**), Loki/Promtail, OpenTelemetry Collector (chart **0.95.0**), plus **monitoring-extras** for rules/dashboards.

## Components

| Path | Purpose |
|------|---------|
| `kube-prometheus-stack/` | Prometheus, Grafana, Alertmanager Helm app (values + Application only) |
| `extras/` | **Canonical** PrometheusRules, ServiceMonitors, Grafana dashboards |
| `loki/` / `promtail/` | In-cluster logging |
| `otel/` | OTLP collector baseline (10% trace sampling) |

## Alerts (single location)

All custom alerts live under `extras/alerts/` and are applied by Argo app **`monitoring-extras`**:

| File | Alerts |
|------|--------|
| `extras/alerts/boutique-availability.yaml` | `BoutiqueFrontendDown`, `BoutiqueDevPodsNotReady` |
| `extras/alerts/platform-health.yaml` | `NodeNotReady`, `KyvernoAdmissionDown`, `IngressCertExpiringSoon` |

## Hostname

`grafana-boutique.biroltilki.art` — TLS via cert-manager DNS-01.

## Prerequisites

- Topic 06 ingress + cert-manager
- Topic 10 Boutique running (dashboards/alerts may reference `boutique-dev`)
- Grafana admin Secret (Topic 11 setup guide)

## Usage

[docs/setup/11-observability.md](../../../docs/setup/11-observability.md) · [docs/operations/10-alerting.md](../../../docs/operations/10-alerting.md)
