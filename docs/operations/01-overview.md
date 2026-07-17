# Overview

**Audience:** L3 — Operator
**Applies to:** dev / stage / prod (one cluster)
**Prerequisites:** Setup Topics 00–12 complete; kubectl context to the test AKS cluster
**Estimated time:** 10 minutes (read)
**Risk level:** Low

## Purpose

Define the operational model: environments, ownership, test constraints, and where other runbooks fit.

## When to use / When not to use

**Use** when joining on-call, before first promotion, or after returning from teardown rebuild.
**Do not use** as a bootstrap guide — see [docs/setup/](../setup/).

## Prerequisites

- [ ] `kubectl get nodes` works
- [ ] Grafana and Argo CD hostnames resolve (or you use port-forward)

## Procedure

### Step 1: Confirm cluster and namespaces

**Commands:**

```bash
kubectl get nodes -o wide
kubectl get ns | grep -E 'boutique|argocd|monitoring|kyverno|ingress'
kubectl get application -n argocd | grep boutique
```

**Validation:** User nodes Ready; boutique Applications present.

**Expected outcome:** At least `boutique-stage` / `boutique-prod` Synced or intentionally OutOfSync; monitoring Running.

**Recovery steps (if this step fails):** Re-run Topic 03 kubeconfig; see [docs/troubleshooting/argocd-sync.md](../troubleshooting/argocd-sync.md).

**Best practices:**

- Prefer GitOps over `kubectl edit` for lasting changes.

### Step 2: Know the environment matrix

| Env | Namespace | Hostname | Argo sync |
|-----|-----------|----------|-----------|
| dev | `boutique-dev` | `dev-boutique.biroltilki.art` | Automatic |
| stage | `boutique-stage` | `stage-boutique.biroltilki.art` | Manual |
| prod | `boutique-prod` | `boutique.biroltilki.art` | Manual + ADO gate when using promote pipeline |

**Test capacity:** Two user nodes with `maxPods≈30` often cannot run full Boutique × 3 + monitoring. Overlays may set optional services and loadgenerator to **0 replicas** (slim storefront). Documented in overlay patches.

**SLO (pilot):** [boutique-availability.md](../slo/boutique-availability.md) — 99.5% frontend health (test measurement).

## End-to-end validation

```bash
./tests/integration/promotion-smoke.sh all
```

## Rollback (section-level)

N/A (read-only orientation).

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| `BoutiqueFrontendDown` | Boutique Overview | `{namespace="boutique-prod"}` |
| `NodeNotReady` | Cluster Overview | — |

## Security notes

Public HTTPS for Argo/Grafana/Boutique — treat credentials as production-sensitive for the test.

## Automation opportunities

Single `ops-status.sh` printing Application + smoke HTTP codes (do not replace this doc).
