# Alerting

**Audience:** L3 — Operator
**Applies to:** PrometheusRule → Alertmanager
**Prerequisites:** kube-prometheus-stack Healthy
**Estimated time:** 15 minutes
**Risk level:** Low

## Purpose

Know which alerts exist, where they are defined, and how to attach runbook links.

## When to use / When not to use

**Use** when wiring notifications, silencing, or verifying alert firing.
**Do not** expect PagerDuty enterprise routing in this solo lab unless you configured receivers.

## Prerequisites

- [ ] Rules synced via Argo app **`monitoring-extras`**
- [ ] Grafana Alerting or Alertmanager UI accessible

## Alert catalog (consolidated)

**Single source of truth:** `gitops/platform/monitoring/extras/alerts/`
Do not add parallel copies under `kube-prometheus-stack/` — those paths were removed as orphans.

| Alert | Severity | File | Meaning | Suggested runbook |
|-------|----------|------|---------|-------------------|
| `BoutiqueFrontendDown` | critical | `boutique-availability.yaml` | frontend available replicas &lt; 1 (`boutique-dev`) | [17](17-common-incidents.md) · [08](08-health-checks.md) |
| `BoutiqueDevPodsNotReady` | warning | `boutique-availability.yaml` | Ready pods &lt; 80% in `boutique-dev` | [04](04-scaling.md) |
| `NodeNotReady` | critical | `platform-health.yaml` | Node not Ready | [17](17-common-incidents.md) |
| `KyvernoAdmissionDown` | critical | `platform-health.yaml` | Admission controller unavailable | [kyverno-admission.md](../troubleshooting/kyverno-admission.md) |
| `IngressCertExpiringSoon` | warning | `platform-health.yaml` | TLS cert near expiry | [14](14-certificate-rotation.md) |

## Procedure

### Step 1: Verify rules on cluster

**Commands:**

```bash
kubectl get prometheusrule -n monitoring
kubectl get prometheusrule -n monitoring boutique-availability -o yaml | head -40
```

**Validation:** Rules exist; labels `release: kube-prometheus-stack` present if required by operator.

### Step 2: Recommend runbook annotations

When editing alerts, add:

```yaml
annotations:
  summary: Boutique frontend unavailable
  runbook_url: https://github.com/<GITHUB_ORG>/<REPO_NAME>/blob/main/docs/operations/17-common-incidents.md
  dashboard_url: https://grafana-boutique.biroltilki.art/dashboards
```

**Validation:** Fire a test alert or inspect Alertmanager UI for annotation presence.

**Expected outcome:** On-call opens runbook from alert.

**Recovery steps:** Sync `monitoring-extras` after Git push.

**Best practices:** Keep `runbook_url` to a stable path on `main`.

## End-to-end validation

Alertmanager Overview dashboard shows receive rate; no unintended paging storm.

## Rollback (section-level)

Revert alert YAML commit; re-sync.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| (all) | Alertmanager / Overview | — |

## Security notes

Do not embed webhook secrets in Git — use CSI/KV or Alertmanager secret.

## Automation opportunities

Extend BoutiqueFrontendDown for `boutique-stage` / `boutique-prod` namespaces.
