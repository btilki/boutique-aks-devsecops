# Monitoring extras (canonical alerts & dashboards)

Argo CD Application: **`monitoring-extras`** → this directory.

| Path | Contents |
|------|----------|
| `alerts/` | PrometheusRules (`boutique-availability`, `platform-health`; `runtime-security` only when Topic 18 enables Falco) |
| `servicemonitors/` | Boutique frontend + ingress-nginx scrapes |
| `dashboards/` | Grafana JSON → ConfigMaps labeled `grafana_dashboard=1` |

**Do not** duplicate these under `kube-prometheus-stack/` — that chart only holds Helm values + Application.

Edit alerts here, push to `main`, then sync `monitoring-extras`.

## Numbering

Roadmap **Phase** numbers differ from Setup **Topic** numbers (for example Roadmap Phase 14 teardown = Setup Topic 13). See [ROADMAP.md](../../../../ROADMAP.md) and [docs/setup/README.md](../../../../docs/setup/README.md).
