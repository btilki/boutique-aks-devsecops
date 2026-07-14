# Monitoring and alerting troubleshooting

Symptoms and fixes for kube-prometheus-stack, Grafana, and Alertmanager ([11-observability.md](../setup/11-observability.md)).

---

## Quick diagnostics

| Check | Command |
|-------|---------|
| Monitoring pods | `kubectl get pods -n monitoring` |
| Argo CD apps | `kubectl get application -n argocd kube-prometheus-stack otel-collector` |
| Grafana ingress | `kubectl get ingress -n monitoring` |
| Prometheus targets | Port-forward Prometheus → Status → Targets |
| Alertmanager | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093` |

---

## Argo CD sync failures

### `kube-prometheus-stack` OutOfSync / CRD errors

**Cause:** Prometheus Operator CRDs not installed yet; sync race.

**Fix:**

1. Sync `platform-root` then `kube-prometheus-stack` manually.
2. Retry with **Replace** only if documented in Argo CD UI for CRDs (avoid blind Replace).
3. Confirm AppProject `monitoring` exists: `kubectl get appproject -n argocd monitoring`.

### PrometheusRule / ServiceMonitor not found

**Cause:** Sync wave 45 resources applied before operator CRDs ready.

**Fix:** Re-sync `platform-root` after `kube-prometheus-stack` is Healthy.

---

## Grafana

### Cannot log in

**Cause:** Missing or wrong `grafana-admin-credentials` Secret.

**Fix:**

```bash
kubectl get secret -n monitoring grafana-admin-credentials
kubectl create secret generic grafana-admin-credentials -n monitoring \
  --from-literal=admin-user=admin \
  --from-literal=admin-password='<YOUR_PASSWORD>'
```

Re-sync Grafana deployment if needed.

### 404 / no dashboards

**Cause:** Dashboard ConfigMaps missing label `grafana_dashboard: "1"`.

**Fix:**

```bash
kubectl get configmap -n monitoring -l grafana_dashboard=1
```

Confirm `grafana-dashboard-cluster-overview` and `grafana-dashboard-boutique-overview` exist. Restart Grafana pod if sidecar did not pick them up.

### TLS / certificate not Ready

**Cause:** DNS for `grafana-boutique.biroltilki.art` not pointing to ingress IP.

**Fix:** Same as Topic 06/10 — Azure DNS A record + wait for cert-manager. See [cert-manager-dns01.md](cert-manager-dns01.md).

---

## Prometheus

### No metrics from boutique-dev

**Cause:** ServiceMonitor selector mismatch or frontend has no `/metrics` endpoint.

**Fix:**

- Deployment health still visible via **kube-state-metrics** (deployment replicas).
- `kubectl get servicemonitor -n monitoring boutique-frontend -o yaml`
- Boutique overview dashboard uses kube-state and ingress metrics, not app `/metrics`.

### No ingress metrics

**Cause:** NGINX metrics port disabled or ServiceMonitor label `release` mismatch.

**Fix:**

```bash
kubectl get svc -n ingress-nginx | grep metrics
kubectl get servicemonitor -n monitoring ingress-nginx
```

Ensure `ingress-nginx` controller values have `controller.metrics.enabled: true`.

---

## Alertmanager

### Alerts not firing

**Cause:** PrometheusRule not selected; expression returns no data.

**Fix:**

```bash
kubectl get prometheusrules -n monitoring
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Open http://localhost:9090/alerts
```

Verify `release: kube-prometheus-stack` label on PrometheusRule resources.

### `IngressCertExpiringSoon` never fires

**Cause:** cert-manager metrics not scraped (optional component).

**Fix:** Informational in lab; check certificates manually:

```bash
kubectl get certificate -A
```

---

## OpenTelemetry Collector

### Collector pod crash loop

**Cause:** Invalid collector config YAML.

**Fix:**

```bash
kubectl logs -n monitoring deploy/otel-collector
kubectl describe application -n argocd otel-collector
```

Compare `otel/values.yaml` with `collector-config.yaml` reference.

### No traces visible

**Expected in v1:** `debug` exporter logs sampled traces to collector pod logs only — no Jaeger/Tempo UI.

```bash
kubectl logs -n monitoring deploy/otel-collector -f
```

---

## Resource pressure (small cluster)

### Prometheus OOMKilled

**Fix:** Reduce retention in `kube-prometheus-stack/values.yaml` or increase memory limits. Lab default: 15d / 2Gi limit.

### Grafana slow

**Fix:** Reduce dashboard time range; disable unused default dashboards if needed.

---

## Reporting issues

Include: Argo CD app status, `kubectl get pods -n monitoring`, failing Prometheus target screenshot, and Grafana/browser error (redact admin password).
