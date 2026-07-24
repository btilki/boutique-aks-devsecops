# Monitoring extras (canonical alerts & dashboards)

Argo CD Application: **`monitoring-extras`** → this directory.

| Path | Contents |
|------|----------|
| `alerts/` | PrometheusRules (`boutique-availability`, `platform-health`, `runtime-security`) |
| `servicemonitors/` | Boutique frontend + ingress-nginx scrapes |
| `dashboards/` | Grafana JSON → ConfigMaps labeled `grafana_dashboard=1` |

**Do not** duplicate these under `kube-prometheus-stack/` — that chart only holds Helm values + Application.

Edit alerts here, push to `main`, then sync `monitoring-extras`.
