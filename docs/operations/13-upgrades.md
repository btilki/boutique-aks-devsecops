# Upgrades

**Audience:** L3 — Operator
**Applies to:** AKS / platform Helm / policies / app digests
**Prerequisites:** `versions.yaml`; healthy backups of state ([06](06-backup-and-restore.md))
**Estimated time:** 1–3 hours depending on layer
**Risk level:** High

## Purpose

Define a safe upgrade order so control plane, platform add-ons, and apps stay compatible.

## When to use / When not to use

**Use** for AKS minor upgrades, Helm chart bumps, Kyverno/Argo versions, Boutique digest rolls.
**Do not** upgrade everything in one unreviewable commit.

## Prerequisites

- [ ] Read release notes for Chart/AKS version
- [ ] Stage smoke green before prod app digest upgrade

## Procedure

### Step 1: Follow upgrade order

1. **Terraform / AKS version** (`kubernetes_version` in tfvars) — plan carefully; system/user pools
2. **Platform Helm** (ingress-nginx, cert-manager, kyverno, kube-prometheus-stack) via GitOps values + chart pins in `versions.yaml`
3. **Kyverno policies** — ensure schema matches controller version
4. **Application digests** — ADO pipeline + [02-deployment.md](02-deployment.md)

**Commands:**

```bash
grep -n 'kubernetes\|kyverno\|argo\|cosign\|trivy' versions.yaml | head -40
cd terraform/environments/dev && terraform plan -lock=false
```

**Validation:** Plan has no surprise destroys; Argo apps Healthy after each layer.

**Expected outcome:** Incremental Healthy syncs.

**Recovery steps:** Revert Git pin; [03-rollback.md](03-rollback.md) for apps; Azure portal for failed AKS upgrade (rare).

**Best practices:** Never skip stage for app digest upgrades.

### Step 2: Platform chart bump example

Edit GitOps Application `targetRevision` / chart version consistently with `versions.yaml`; sync one app at a time (`kube-prometheus-stack` last/first thoughtfully — CRDs need ServerSideApply already set).

## End-to-end validation

Health checks + smoke; watch alerts 30 minutes.

## Rollback (section-level)

Revert version pins in Git; sync. Cluster downgrades are rarely supported — prefer forward fix.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| `KyvernoAdmissionDown` | — | — |

## Security notes

Image bumps must remain signed/scanned.

## Automation opportunities

Dependabot-style chart PRs with required smoke on stage.
