# Backup and restore

**Audience:** L3 — Operator
**Applies to:** Terraform state, Key Vault, Git (primary)
**Prerequisites:** Azure RBAC on state storage + Key Vault
**Estimated time:** 15–45 minutes
**Risk level:** Medium

## Purpose

Describe what is backed up for this **demo/pilot** stack and how to restore critical control-plane data. Boutique has **no durable app database** to back up.

## When to use / When not to use

**Use** before risky TF apply, key rotation, or teardown.
**Do not** expect volume snapshots for Redis emptyDir cart data (ephemeral).

## Prerequisites

- [ ] Know bootstrap storage account + container (`terraform/bootstrap`)
- [ ] Soft-delete awareness on Key Vault (7 days; purge protection often **off** for test)

## Procedure

### Step 1: Confirm Terraform state protection

**Commands:**

```bash
# Blob versioning enabled on bootstrap storage (Topic 01)
az storage account blob-service-properties show \
  --account-name <TF_STATE_STORAGE> \
  --query '{versioning:isVersioningEnabled}' -o json
```

**Validation:** Versioning enabled.

**Expected outcome:** Prior state versions available after overwrite.

**Recovery steps:** Restore prior blob version via Azure Portal → Storage → container → versions; then `terraform init`.

**Best practices:** Never delete the state container casually.

### Step 2: Key Vault soft-delete

**Commands:**

```bash
az keyvault secret list-deleted --vault-name <KEY_VAULT_NAME> -o table
# Recover (example):
# az keyvault secret recover --vault-name <KEY_VAULT_NAME> --name cosign-private-key
```

**Validation:** Secret present after recover; pipeline can sign.

### Step 3: Git as source of truth

**Commands:**

```bash
git fetch origin && git rev-parse origin/main
```

**Validation:** Manifests and policies recoverable from remote.

## End-to-end validation

After state restore: `terraform plan` should be sensible (no unexpected destroy-all).

## Rollback (section-level)

If wrong state version restored, select an older version and re-init.

## Related alerts and dashboards

N/A.

## Security notes

State may contain sensitive attributes — restrict Storage RBAC; no public container ACLs.

## Automation opportunities

Periodic export of KV secret *names* inventory (not values) to ops notes.
