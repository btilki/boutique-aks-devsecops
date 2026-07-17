# Logging

**Audience:** L3 — Operator
**Applies to:** Loki + Promtail in `monitoring`
**Prerequisites:** ADR-0012; Grafana Loki datasource
**Estimated time:** 10 minutes
**Risk level:** Low

## Purpose

Query workload and platform logs during incidents without Azure Log Analytics.

## When to use / When not to use

**Use** for pod crash loops, ingress 5xx, Kyverno denials (if logged).
**Do not** expect infinite retention — PVC-sized Loki (test ~10Gi).

## Prerequisites

- [ ] Promtail DaemonSet Running (or designed slim profile)
- [ ] Grafana Explore → Loki

## Procedure

### Step 1: Query Boutique logs

**GUI steps:**

1. Grafana → **Explore** → datasource **Loki**
2. Example LogQL:

```logql
{namespace="boutique-prod"} |= "error"
{namespace="boutique-prod", app="frontend"}
{namespace="ingress-nginx"}
```

**Validation:** Streams return recent lines for Running pods.

**Expected outcome:** Correlate error timestamps with deploy time.

**Recovery steps:** If no data — check Promtail pods, Loki single-binary, PVC free space ([monitoring-alerting.md](../troubleshooting/monitoring-alerting.md)).

**Best practices:** Prefer `kubectl logs` for one-shot; Loki for historical.

### Step 2: kubectl fallback

**Commands:**

```bash
kubectl logs -n boutique-prod deploy/frontend --tail=100
kubectl logs -n boutique-prod deploy/frontend --previous
```

**Validation:** Logs readable without permission errors.

## End-to-end validation

Generate traffic (browser storefront) → see ingress or frontend lines within scrape interval.

## Rollback (section-level)

N/A.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| `BoutiqueFrontendDown` | Boutique Overview | `{namespace="boutique-prod"}` |

## Security notes

Logs may contain request paths — avoid shipping secrets in app env.

## Automation opportunities

Recording rules for log-based error rates (optional).
