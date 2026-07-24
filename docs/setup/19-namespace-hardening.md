# 19 — Namespace & Key Vault Hardening

**Audience:** L2 — Implementer
**Estimated time:** 45–90 minutes
**Prerequisites:** [03-cluster-resources.md](03-cluster-resources.md) · [07-secrets-csi.md](07-secrets-csi.md) · [10-boutique-dev.md](10-boutique-dev.md)
**Creates:** PSA labels + ResourceQuota/LimitRange on Boutique namespaces; optional KV purge protection + network ACL Deny
**Related ADRs:** [0016](../adr/0016-namespace-kv-hardening.md), [0010](../adr/0010-destroy-acr-on-teardown.md)
**Mode:** GitOps hardening is in-repo now. KV Deny/purge flips are **Apply later** (and may complicate teardown).

---

## Topic goal

When this topic is complete:

1. Each `boutique-*` namespace enforces **Pod Security Admission baseline** (warn/audit restricted).
2. **LimitRange** + **ResourceQuota** cap container defaults and namespace totals.
3. You can optionally lock Key Vault with **network ACL Deny** (AKS subnet allow-list) and/or **purge protection**.

## Why this topic is required

Kyverno baseline does not replace namespace PSA labels or quotas. Public Key Vault + no purge protection were intentional pilot tradeoffs (Checkov skips in Topic 16); this topic makes hardening a documented, reversible apply path.

---

## Before you begin

```bash
cd /path/to/boutique-aks-devsecops
kubectl kustomize gitops/apps/boutique/overlays/dev | grep -E 'kind: (Namespace|ResourceQuota|LimitRange)|pod-security|boutique-resource-quota|boutique-limit-range'
grep -n service_endpoints terraform/modules/networking/main.tf
grep -n network_acls terraform/modules/key-vault/main.tf
```

**Expected:** PSA labels on Namespace; ResourceQuota + LimitRange present; subnet `Microsoft.KeyVault` endpoint; KV `network_acls` block.

---

## Step 19.1: Review namespace hardening manifests

### Goal

Confirm PSA + quota design (ADR-0016).

| Control | Value |
|---------|--------|
| PSA enforce | `baseline` |
| PSA warn/audit | `restricted` |
| Quota | 50 pods / 4 CPU req / 8Gi mem req (see YAML) |
| LimitRange | defaultRequest 50m/64Mi; max 2 CPU / 2Gi |

### Validation

- [ ] `gitops/apps/boutique/base/hardening/` included from base kustomization
- [ ] All three overlay `namespace.yaml` files have PSA labels

---

## Step 19.2: Sync GitOps — **Apply later**

### Goal

Apply PSA labels, quotas, and limit ranges to live namespaces.

```bash
kubectl get ns boutique-dev --show-labels | tr ',' '\n' | grep pod-security
kubectl get resourcequota,limitrange -n boutique-dev
kubectl describe resourcequota boutique-resource-quota -n boutique-dev
```

### Validation

- [ ] Labels present; Boutique pods still Ready
- [ ] If a pod fails PSA, fix securityContext (Kyverno/non-root patches already help)
- [ ] If quota exceeded, raise `resource-quota.yaml` and sync (do not remove quotas silently)

---

## Step 19.3: Optional Key Vault network ACL Deny — **Apply later**

### Goal

Block public KV data-plane except AKS subnet (+ optional operator IPs).

### Prerequisites

- AKS subnet already has `service_endpoints = ["Microsoft.KeyVault"]` (scaffolded in networking module)
- CSI + Workload Identity path tested **before** Deny (Topic 07)

### Commands

In `terraform/environments/dev/terraform.tfvars`:

```hcl
kv_network_acls_default_action = "Deny"
# Optional break-glass / operator IP:
# kv_network_acls_ip_rules = ["203.0.113.10"]
```

```bash
cd terraform/environments/dev
terraform plan
terraform apply
```

Env wiring auto-passes `module.networking.aks_subnet_id` when action is Deny.

### Validation

```bash
az keyvault show -n <KEY_VAULT_NAME> --query properties.networkAcls -o json
# defaultAction: Deny; virtualNetworkRules includes AKS subnet
```

- [ ] CSI test / Grafana secret mount still works
- [ ] ADO pipeline can still read cosign key (Microsoft-hosted agents may need **ip_rules** or run on a self-hosted agent in the VNet — validate!)

**Warning:** Azure DevOps **Microsoft-hosted** agents are not on your AKS subnet. With Deny-only-subnet, pipeline KV reads may fail unless you add agent IPs, use a self-hosted agent, or keep `bypass = AzureServices` (does **not** replace subnet allow for all cases). Test Topic 09 after enabling Deny.

---

## Step 19.4: Optional purge protection — **Apply later**

### Goal

Prevent immediate purge of soft-deleted vaults/secrets.

```hcl
kv_purge_protection_enabled = true
```

### Validation

- [ ] `az keyvault show -n <KEY_VAULT_NAME> --query properties.enablePurgeProtection`
- [ ] Understand teardown: purge protection **blocks** quick vault destroy — plan retention days / wait before full cleanup

**Keep `false`** on short-lived cost tests (ADR-0010 teardown path).

---

## Step 19.5: Update Checkov skips when hardened

After Deny ACL and/or purge protection are live and intentional:

1. Remove from `tests/terraform/.checkov.yaml` as applicable: `CKV_AZURE_109`, `CKV_AZURE_189`, `CKV_AZURE_110` (and `CKV_AZURE_42` if satisfied)
2. Run `make checkov`

---

## Rollback

| Control | Rollback |
|---------|----------|
| PSA / quota | Revert namespace labels / delete ResourceQuota+LimitRange from base, sync |
| KV ACL | Set `kv_network_acls_default_action = "Allow"`, apply |
| Purge protection | **Cannot disable** once enabled on a vault — create new vault or wait out retention |

---

## End-to-end validation checklist

### Scaffold

- [x] Hardening manifests + PSA labels
- [x] KV module ACL/purge variables; subnet service endpoint
- [x] ADR-0016 + this topic

### Apply later

- [ ] Boutique namespaces show PSA + quota
- [ ] Optional: KV Deny validated with CSI + pipeline
- [ ] Optional: purge protection decision documented for your env

---

## Related docs

| Doc | Role |
|-----|------|
| [07-secrets-csi.md](07-secrets-csi.md) | CSI before KV ACL |
| [16-iac-scanning.md](16-iac-scanning.md) | Checkov skip maintenance |
| [secrets-management.md](../security/secrets-management.md) | Secrets overview |
| [13-teardown.md](13-teardown.md) | Destroy path vs purge protection |
| [20-dast.md](20-dast.md) | Next package (optional DAST) |
