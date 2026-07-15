# Loki

In-cluster log store (SingleBinary) deployed via Argo CD. Replaces Azure Log Analytics per [ADR-0012](../../../../docs/adr/0012-loki-in-cluster-logging.md).

- **Chart:** `grafana/loki` — version in [versions.yaml](../../../../versions.yaml)
- **Sync wave:** 38 (before Promtail and kube-prometheus-stack)
- **Grafana datasource:** configured in `kube-prometheus-stack/values.yaml`
