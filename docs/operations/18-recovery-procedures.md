# Recovery procedures

**Audience:** L3 — Operator
**Applies to:** Major multi-component failures
**Prerequisites:** [05-disaster-recovery.md](05-disaster-recovery.md), [17-common-incidents.md](17-common-incidents.md)
**Estimated time:** 30 minutes–hours
**Risk level:** High

## Purpose

Ordered recovery paths when several subsystems fail together.

## When to use / When not to use

**Use** if common playbooks alone do not restore SEV-1.
**Do not** skip health validation between steps.

## Prerequisites

- [ ] Incident commander notes (You)
- [ ] Prefer stage recovery before prod if both broken

## Procedure

### Path A — API / kubectl works; storefront down

1. [17 Playbook CrashLoop / Pending](17-common-incidents.md)
2. Ingress + Certificate ([14](14-certificate-rotation.md))
3. Smoke ([08](08-health-checks.md))
4. Rollback digest if post-deploy ([03](03-rollback.md))

**Validation:** `promotion-smoke.sh` for affected env.

### Path B — Argo CD broken; cluster up

1. [argocd-sync.md](../troubleshooting/argocd-sync.md)
2. Fix Git / AppProject / SSA
3. Sync platform-root then boutique apps
4. Smoke

### Path C — Cluster API unreachable

1. Azure Portal → AKS → stop/start **only** if documented emergency
2. Restore kubeconfig (`az aks get-credentials`)
3. If cluster destroyed → [05-disaster-recovery.md](05-disaster-recovery.md)

### Path D — Key Vault / signing broken

1. Soft-delete recover ([06](06-backup-and-restore.md))
2. [15-secret-rotation.md](15-secret-rotation.md) if keys lost
3. Re-run ADO pipeline; resync Kyverno public key

**Expected outcome:** Signing works; Boutique admits images.

**Recovery steps:** Remirror entire Boutique set if ACR signatures wipe.

**Best practices:** Stop promotions until Path D complete.

## End-to-end validation

All smoke scripts for environments you intend to serve; Grafana up; no critical Pending for frontend.

## Rollback (section-level)

Document abandoned paths; do not leave half-synced apps.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| Multiple firing | Alertmanager Overview | — |

## Security notes

Emergency cluster stop/start is audited in Azure Activity Log — capture ticket id.

## Automation opportunities

Printed recovery card (PDF) for offline outages.
