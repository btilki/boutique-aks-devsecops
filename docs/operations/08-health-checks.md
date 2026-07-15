# Health checks

**Audience:** L3 — Operator
**Applies to:** Boutique + platform ingress + GitOps sync
**Prerequisites:** DNS/TLS for hostnames; scripts executable
**Estimated time:** 5–15 minutes
**Risk level:** Low

## Purpose

Prove the platform is healthy after deploy, rollback, incident mitigation, or a **morning check** using smoke tests, kubectl probes, and **Argo CD sync health**.

## When to use / When not to use

**Use** after every promote, rollback, maintenance window, or morning check.
**Do not** treat a single green curl as full cluster health if Argo shows **OutOfSync** or **Degraded** on critical apps.

## Prerequisites

- [ ] Repo root as cwd
- [ ] kubectl context correct

## Morning checklist (≈5 min)

Run in order; stop and escalate if a gate fails.

| # | Gate | Pass criteria |
|---|------|---------------|
| 1 | **Argo sync health** | Critical apps **Synced** + **Healthy** |
| 2 | Workload readiness | Boutique pods Ready; certs Ready |
| 3 | Smoke tests | `/_healthz` and `/` HTTP 200 |
| 4 | Platform pulse | Grafana login **200**; monitoring pods up |

---

## Procedure

### Step 1: Argo CD sync health (keep every morning)

**Why:** Green smokes with OutOfSync GitOps still mean drift or a failed reconcile.

**Commands:**

```bash
# Boutique + platform roots
kubectl get applications -n argocd \
  -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status

# Critical set for morning (expect Synced Healthy)
kubectl get application -n argocd \
  boutique-dev boutique-stage boutique-prod \
  platform-root apps-root \
  kube-prometheus-stack kyverno \
  -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status
```

**Validation:**

| App | Expected SYNC | Expected HEALTH | Notes |
|-----|---------------|-----------------|-------|
| `boutique-dev` | Synced | Healthy | Auto-sync |
| `boutique-stage` | Synced | Healthy | Manual sync after promote |
| `boutique-prod` | Synced | Healthy | Manual sync + ADO prod gate |
| `platform-root` / `apps-root` | Synced | Healthy | Parent apps |
| `kube-prometheus-stack` | Synced | Healthy | Observability |
| `kyverno` | Synced | Healthy | Admission |

**Expected outcome:** No `OutOfSync`, `Unknown`, or `Degraded` on the critical set.

**Recovery steps:** [argocd-sync.md](../troubleshooting/argocd-sync.md) · playbook [17-common-incidents.md](17-common-incidents.md#playbook-2--gitops-outofsync--sync-error).

**Best practices:** Check sync health **before** relying on curl alone. Stage/prod OutOfSync after a Git push usually means a manual sync was skipped.

### Step 2: Workload readiness

**Commands:**

```bash
kubectl get pods -n boutique-dev -o wide
kubectl get pods -n boutique-stage -o wide
kubectl get pods -n boutique-prod -o wide
kubectl get ingress -A | grep -E 'boutique|grafana|argocd'
kubectl get certificate -A | grep -E 'boutique|grafana|argocd'
```

**Validation:** Core Deployments Ready; Certificate `Ready=True`.

### Step 3: Integration smokes

**Commands:**

```bash
./tests/integration/dev-smoke.sh                    # if boutique-dev running
./tests/integration/promotion-smoke.sh stage
./tests/integration/promotion-smoke.sh prod
# or: ./tests/integration/promotion-smoke.sh all
```

**Validation:** Exit code 0; HTTP 200 on `/_healthz` and `/`.

**Expected outcome:** PASS lines printed.

**Recovery steps:** Pending pods → scaling; 503 → ingress/backends; TLS → certificates.

**Best practices:** Run stage before prod after promote.

### Step 4: Platform pulse

**Commands:**

```bash
kubectl get pods -n monitoring | grep -E 'prometheus|grafana'
curl -sS -o /dev/null -w "%{http_code}\n" https://grafana-boutique.biroltilki.art/login
curl -sS -o /dev/null -w "%{http_code}\n" https://argocd-boutique.biroltilki.art/  || true
```

**Validation:** Grafana login page **200**; Prometheus/Grafana pods Running.

## End-to-end validation

Match SLO probe intent: [boutique-availability.md](../slo/boutique-availability.md).

## Rollback (section-level)

If checks fail after a change, execute [03-rollback.md](03-rollback.md).

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| `BoutiqueFrontendDown` | Boutique Overview | — |

## Security notes

Health endpoints are public — no auth cookies with secrets.

## Automation opportunities

CronJob or ADO nightly job: assert Argo `Synced`/`Healthy` + smoke scripts; optional Alertmanager webhook.
