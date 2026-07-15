# Observability

## Stack

| Layer | Technology | Repo path |
|-------|------------|-----------|
| Metrics | Prometheus (kube-prometheus-stack) | `gitops/platform/monitoring/kube-prometheus-stack/` |
| Dashboards | Grafana | same |
| Alerting | Alertmanager | same |
| Logs | Loki + Promtail | `gitops/platform/monitoring/loki/`, `promtail/` |
| Traces | OpenTelemetry Collector | `gitops/platform/monitoring/otel/` |

**Grafana hostname:** `grafana-boutique.biroltilki.art`

See [ADR-0012](../adr/0012-loki-in-cluster-logging.md) — Azure Log Analytics is **not** deployed in the default lab path.

## Metrics

| Source | Method |
|--------|--------|
| Cluster / nodes | kube-prometheus-stack defaults |
| NGINX ingress | Ingress controller metrics |
| Boutique frontend | ServiceMonitor |
| Platform pods | ServiceMonitors as needed |

**Retention:** 15 days (configurable in Helm values).

## Logs

- **Centralized:** Promtail → Loki; query in Grafana Explore (LogQL)
- **Ad-hoc:** `kubectl logs` for quick checks
- **Retention:** Loki filesystem PVC (~10Gi lab default)

Example LogQL: `{namespace="boutique-dev", app="frontend"}`

## Traces

OTel collector deployed with baseline OTLP receiver. Full Tempo/Jaeger backend deferred. Sampling: ~10% for pilot.

## Alerting

Canonical rules: `gitops/platform/monitoring/extras/alerts/` (Argo app `monitoring-extras`).

| Alert | Condition | Audience |
|-------|-----------|----------|
| `BoutiqueFrontendDown` | frontend available replicas &lt; 1 for 5m (`boutique-dev`) | Platform engineer |
| `BoutiqueDevPodsNotReady` | Ready pods &lt; 80% in `boutique-dev` for 10m | Platform engineer |
| `IngressCertExpiringSoon` | cert &lt; 14 days | Platform engineer |
| `NodeNotReady` | node NotReady 10m | Platform engineer |
| `KyvernoAdmissionDown` | Kyverno admission replicas &lt; 1 for 5m | Platform engineer |

Notification channels (email/Slack) disabled by default in lab; Alertmanager UI used for validation. Ops guide: [10-alerting.md](../operations/10-alerting.md).

## Dashboards

| Dashboard | File |
|-----------|------|
| Cluster overview | `gitops/platform/monitoring/extras/dashboards/cluster-overview.json` |
| Boutique overview | `gitops/platform/monitoring/extras/dashboards/boutique-overview.json` |

## SLO

Documented in `docs/slo/boutique-availability.md` (Phase 11).

## On-call (solo lab)

Owner verifies Grafana after deploys. No formal escalation path in v1.
