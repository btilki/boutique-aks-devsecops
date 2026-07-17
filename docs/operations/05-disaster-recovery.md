# Disaster recovery

**Audience:** L3 — Operator
**Applies to:** Entire test platform
**Prerequisites:** Git remote healthy; Azure access; Setup guides available
**Estimated time:** Hours (full rebuild)
**Risk level:** High

## Purpose

Recover from loss of cluster, subscription misconfiguration, or deliberate teardown — **rebuild-from-Git**, not multi-region failover.

## When to use / When not to use

**Use** after catastrophic AKS failure, accidental destroy, or post-teardown rebuild.
**Do not** expect automatic DR; this is a solo pilot test (no secondary region).

## Prerequisites

- [ ] Git clone of this repo on `main`
- [ ] Terraform state storage still exists (or bootstrap again — Topic 01)
- [ ] DNS zone ownership intact

## Procedure

### Step 1: Assess what remains

**Commands:**

```bash
az group show -n rg-boutique-dev-gwc -o table 2>/dev/null || echo "platform RG gone"
az acr show -n acrboutiquedevgwc -o table 2>/dev/null || echo "ACR gone — remirror required"
```

**Validation:** Know whether TF state / ACR / DNS survived.

**Expected outcome:** Clear rebuild checklist.

**Test targets (honest):**

| Metric | Target |
|--------|--------|
| RTO | Rebuild platform same day (solo) |
| RPO | Git + last signed digests in ACR (if ACR destroyed → remirror) |

### Step 2: Rebuild foundation

Follow Setup Topics **01 → 03** (state, network, AKS/ACR/KV) using existing tfvars values where safe.

### Step 3: Platform + apps

Follow Topics **04–12** as needed: OIDC, GitOps, ingress, CSI, Kyverno, CI remirror, Boutique, monitoring, promote.

**Validation:** Smoke scripts pass; Argo apps Healthy.

**Recovery steps:** If ACR wiped, queue ADO pipeline before Boutique sync.

## End-to-end validation

`./tests/integration/promotion-smoke.sh all` (+ dev if capacity allows).

## Rollback (section-level)

N/A — DR ends in a newly rebuilt system. Document learnings in postmortem.

## Related alerts and dashboards

None until monitoring is restored.

## Security notes

Recreate / rotate cosign keys if Key Vault was destroyed ([15-secret-rotation.md](15-secret-rotation.md)).

## Automation opportunities

Documented teardown + rebuild drill schedule (quarterly).
