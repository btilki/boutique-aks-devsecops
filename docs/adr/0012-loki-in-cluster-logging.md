# ADR-0012: In-cluster Loki instead of Azure Log Analytics

## Status

Accepted

## Context

Azure Log Analytics bills primarily on **ingestion volume**. For a solo lab, Container Insights and platform diagnostic settings can cost more than the rest of the stack combined with little benefit — metrics and dashboards already run in-cluster via kube-prometheus-stack (Prometheus + Grafana).

The project needs centralized log search in Grafana for platform and Boutique troubleshooting without recurring Azure Monitor ingestion charges.

## Decision

1. **Do not deploy** a Log Analytics workspace or Container Insights (`oms_agent`) in the default lab path.
2. Deploy **Grafana Loki** (SingleBinary) and **Promtail** via GitOps under `gitops/platform/monitoring/`.
3. Configure Grafana with a **Loki datasource** alongside Prometheus.
4. Keep the `terraform/modules/diagnostics/` module in the repo for optional future use but **do not wire it** in `terraform/environments/dev/main.tf`.

## Consequences

- **Positive:** No Log Analytics ingestion cost; unified logs + metrics in Grafana; logs stay in-cluster.
- **Negative:** No Azure Portal audit trail for AKS API / ACR / Key Vault diagnostic logs; Loki uses cluster disk and node resources (~10Gi PVC + Promtail DaemonSet overhead).
- **Operational:** Use Grafana **Explore → Loki** or `{namespace="boutique-dev"}` LogQL queries; `kubectl logs` remains valid for ad-hoc checks.

## References

- [10-observability.md](../architecture/10-observability.md)
- [11-observability.md](../setup/11-observability.md)
- `gitops/platform/monitoring/loki/`, `gitops/platform/monitoring/promtail/`
