# Observability

## Stack

| Layer | Technology | Repo path |
|-------|------------|-----------|
| Metrics | Prometheus (kube-prometheus-stack) | `gitops/platform/monitoring/kube-prometheus-stack/` |
| Dashboards | Grafana | same |
| Alerting | Alertmanager | same |
| Traces | OpenTelemetry Collector | `gitops/platform/monitoring/otel/` |
| Audit logs | Azure Log Analytics | `terraform/modules/diagnostics/` |

**Grafana hostname:** `grafana-boutique.biroltilki.art`

## Metrics

| Source | Method |
|--------|--------|
| Cluster / nodes | kube-prometheus-stack defaults |
| NGINX ingress | Ingress controller metrics |
| Boutique frontend | ServiceMonitor |
| Platform pods | ServiceMonitors as needed |

**Retention:** 15 days (configurable in Helm values).

## Logs

- **Platform audit:** AKS, ACR, Key Vault → Log Analytics (Terraform diagnostics)
- **Workload logs:** `kubectl logs` / Azure Monitor container insights (optional)

Structured logging expected from Boutique services; no centralized Loki in v1.

## Traces

OTel collector deployed with baseline OTLP receiver. Full Tempo/Jaeger backend deferred. Sampling: ~10% for pilot.

## Alerting

| Alert | Condition | Audience |
|-------|-----------|----------|
| BoutiqueDown | `frontend` up == 0 for 5m | Platform engineer |
| IngressCertExpiring | cert < 14 days | Platform engineer |
| NodeNotReady | node unready 10m | Platform engineer |
| KyvernoDown | kyverno pods unavailable | Platform engineer |

Notification channels (email/Slack) disabled by default in lab; Alertmanager UI used for validation.

## Dashboards

| Dashboard | File |
|-----------|------|
| Cluster overview | `gitops/platform/monitoring/dashboards/cluster-overview.json` |
| Boutique overview | `gitops/platform/monitoring/dashboards/boutique-overview.json` |

## SLO

Documented in `docs/slo/boutique-availability.md` (Phase 11).

## On-call (solo lab)

Owner verifies Grafana after deploys. No formal escalation path in v1.
