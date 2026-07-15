# Secret rotation

**Audience:** L3 — Operator
**Applies to:** Cosign keys, Grafana admin, CSI-mounted secrets
**Prerequisites:** [secrets-management.md](../security/secrets-management.md)
**Estimated time:** 30–60 minutes (cosign)
**Risk level:** High

## Purpose

Rotate platform secrets without leaving Git or pipelines on stale material. This section summarizes; **canonical detail** is the security doc.

## When to use / When not to use

**Use** after suspected leak, operator offboarding, or scheduled lab rotation.
**Do not** commit private keys to Git “temporarily.”

## Prerequisites

- [ ] Key Vault Secrets Officer / Administrator access (break-glass)
- [ ] Ability to sync Kyverno policies and rerun ADO pipeline

## Procedure

### Step 1: Follow inventory

Open [secrets-management.md](../security/secrets-management.md) — inventory + cosign / Grafana rotate sections.

### Step 2: Cosign (summary)

**Commands:**

```bash
# Generate new key pair offline; set KV secrets cosign-private-key / cosign-public-key
# Update policies/kyverno/cluster/02-verify-image-signatures.yaml public PEM
git add policies/kyverno/cluster/02-verify-image-signatures.yaml
git commit -m "security: rotate cosign public key in Kyverno"
git push origin main
# Sync kyverno-policies; rerun ADO pipeline to re-sign digests
```

**Validation:** `cosign verify` on a new digest; Boutique still admits signed images.

**Expected outcome:** Old key unused; pipeline green.

**Recovery steps:** Recover soft-deleted KV secret if mistaken delete ([06](06-backup-and-restore.md)).

**Best practices:** Rotate public+private together; stage sync first.

### Step 3: Grafana admin

Update KV / K8s secret per Topic 11 pattern; restart Grafana if required; login test.

## End-to-end validation

Pipeline sign + smoke; Grafana login.

## Rollback (section-level)

Re-publish previous public key only if still valid pairs exist in KV — prefer forward.

## Related alerts and dashboards

N/A.

## Security notes

Aligns with Security Prompt near-term secrets findings; purge protection may be off in lab.

## Automation opportunities

Documented calendar reminder; no auto keygen in CI without approval gate.
