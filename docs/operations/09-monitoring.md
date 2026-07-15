# Monitoring

**Audience:** L3 — Operator
**Applies to:** `monitoring` namespace · Grafana
**Prerequisites:** Topic 11 complete; Grafana admin secret
**Estimated time:** 10 minutes
**Risk level:** Low

## Purpose

Navigate the metrics/dashboards stack and know which views matter during incidents.

## When to use / When not to use

**Use** for golden signals, capacity, and alert validation.
**Do not** use Azure Log Analytics (not deployed — ADR-0012); use Grafana + Loki.

## Prerequisites

- [ ] `https://grafana-boutique.biroltilki.art` reachable
- [ ] Prometheus datasource default in Grafana

## Procedure

### Step 1: Open critical dashboards

**GUI steps:**

1. Navigate to Grafana → **Dashboards**
2. Open in order:
   - **Boutique Overview** (replicas, pods, ingress rate)
   - **Cluster Overview** / Kubernetes mixin compute
   - **Alertmanager / Overview**

**Validation:** Boutique Overview shows expected replica counts for the env you care about.

**Expected outcome:** Panels populate (not “No data” for > scrape interval).

**Recovery steps:** Check Prometheus pods; ServiceMonitors; see [monitoring-alerting.md](../troubleshooting/monitoring-alerting.md).

**Best practices:** Bookmark Boutique Overview for SEV-1.

### Step 2: Confirm Prometheus targets briefly

**Commands:**

```bash
kubectl get prometheus,prometheusrule -n monitoring
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
```

**Validation:** Prometheus Running; rules present (`boutique-availability`, platform-health).

## End-to-end validation

```bash
curl -sS -o /dev/null -w "%{http_code}\n" https://grafana-boutique.biroltilki.art/login
```

Expect `200`.

## Rollback (section-level)

N/A for viewing. To restore Grafana: sync Argo `kube-prometheus-stack` / `monitoring-extras`.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| All boutique alerts | Boutique Overview | — |

Screenshots: [assets/images/setup/11-*.png](../../assets/images/setup/).

## Security notes

Grafana admin is a high-value credential — rotate via [15-secret-rotation.md](15-secret-rotation.md).

## Automation opportunities

Folder + starred dashboards via Grafana provisioning (already partly via extras).
