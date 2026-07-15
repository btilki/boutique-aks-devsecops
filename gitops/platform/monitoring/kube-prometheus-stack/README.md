# kube-prometheus-stack

Helm chart **58.2.2** from `prometheus-community` — deploys Prometheus Operator, Prometheus, Grafana, Alertmanager, kube-state-metrics, node-exporter.

- Values: `values.yaml`
- Argo CD Application: `Application.yaml` (project: `monitoring`)
- Custom alerts / ServiceMonitors / dashboards: **`../extras/`** (Argo app `monitoring-extras`) — not in this directory

Grafana ingress hostname: `grafana-boutique.biroltilki.art`
