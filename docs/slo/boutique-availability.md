# Boutique availability SLO

Service level objective for Online Boutique **frontend** in the dev environment (pilot). Stage and prod inherit the same target when promoted.

**Related:** [10-observability.md](../architecture/10-observability.md), PrometheusRule `boutique-availability`

---

## Service

| Field | Value |
|-------|-------|
| **SLI scope** | HTTP `GET /_healthz` on frontend via ingress |
| **Hostname (dev)** | `dev-boutique.biroltilki.art` |
| **Namespace** | `boutique-dev` |
| **Deployment** | `frontend` |

---

## SLO target

| Metric | Target | Window |
|--------|--------|--------|
| **Availability** | **99.5%** successful health checks | Rolling 30 days |
| **Latency (p95)** | < 500 ms for `/_healthz` | Rolling 7 days (informational) |

**Error budget (30d):** 0.5% downtime ≈ **3.6 hours** per month.

---

## SLI measurement

### Primary (lab)

Manual / scripted probe aligned with smoke test:

```bash
./tests/integration/dev-smoke.sh
```

### Prometheus (platform)

| Signal | PromQL (indicative) |
|--------|---------------------|
| Replicas available | `kube_deployment_status_replicas_available{namespace="boutique-dev", deployment="frontend"}` |
| Pod ready ratio | `sum(kube_pod_status_ready{namespace="boutique-dev", condition="true"}) / count(kube_pod_info{namespace="boutique-dev"})` |
| Ingress 5xx rate | `sum(rate(nginx_ingress_controller_requests{ingress=~\"boutique.*\", status=~\"5..\"}[5m]))` |

Alert **`BoutiqueFrontendDown`** fires when frontend replicas &lt; 1 for 5 minutes.

---

## Error budget policy (solo lab)

| Burn rate | Action |
|-----------|--------|
| Budget remaining &gt; 50% | Normal development |
| 25–50% | Pause non-critical changes; review recent deploys |
| &lt; 25% | Freeze promotions to stage/prod until root cause resolved |
| Exhausted | Incident review; rollback digest in GitOps overlay |

No automated paging in v1 — operator checks Grafana and Alertmanager after deploys.

---

## Exclusions

- Planned maintenance (documented in change log)
- Platform outages (AKS control plane, ingress controller down) tracked separately under platform SLOs
- Load generator synthetic traffic failures (does not affect user-facing SLI)

---

## Review cadence

- **Weekly:** Glance at Boutique Overview dashboard during active development
- **Per promotion:** Confirm frontend replicas and smoke test before stage/prod sync (Topic 12)

---

## Future improvements

- Blackbox exporter probing `/_healthz` from outside the cluster
- Recording rules for monthly availability percentage
- Multi-window burn-rate alerts (Google SRE workbook pattern)
