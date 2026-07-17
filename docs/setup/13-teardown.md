# 13 — Teardown

**Audience:** L2 — Implementer
**Estimated time:** 60 minutes (destroy may take 15–30 minutes)
**Prerequisites:** [12-promotion-stage-prod.md](12-promotion-stage-prod.md) ✅ (or explicit decision to abandon test)
**Destroys:** AKS, ACR, Key Vault, VNet, Azure DNS zone, platform resource group
**Related ADRs:** [0010](../adr/0010-destroy-acr-on-teardown.md)

---

## Topic goal

When this topic is complete, **billable Azure platform resources** from Topics 02–04 are **destroyed**, including **ACR and all mirrored images**. Terraform remote state **bootstrap** storage is **retained by default** for faster rebuild. You can verify **no AKS/ACR** resources remain in the subscription.

## Why this topic is required

The test targets **€150–250/month** when active. Teardown stops ongoing compute, registry, and load balancer charges. ADR-0010 requires ACR destruction — rebuild requires re-running the mirror pipeline (Topic 09).

---

## Before you begin

- [ ] Promotion/smoke tests documented or no longer needed
- [ ] Cosign **public** key preserved in Git (`policies/kyverno/cluster/02-verify-image-signatures.yaml`)
- [ ] Optional: backup `terraform/environments/dev/terraform.tfvars` locally (no secrets in Git)
- [ ] `az login` active on correct subscription
- [ ] Understand DNS at registrar may need NS update if Azure DNS zone is destroyed

```bash
az account show --query "{name:name, id:id}" -o table
cd terraform/environments/dev
terraform output -raw resource_group_name 2>/dev/null || grep resource_group_name terraform.tfvars
```

---

## Step 13.1: Pre-teardown checklist

### Goal

Prevent data loss surprises and stop automated jobs hitting a dying cluster.

### Why this step is required

Pipelines and Argo CD will error loudly during destroy; ADO history remains but live resources should be intentionally stopped.

### Commands

```bash
# Optional — final smoke record
./tests/integration/promotion-smoke.sh all 2>/dev/null || true

# Pause ADO pipelines (GUI): Pipelines → disable boutique pipelines

# Optional — remove GitOps apps before destroy (if cluster reachable)
kubectl get application -n argocd 2>/dev/null || echo "Cluster already gone or kubeconfig stale"
```

Export reminders:

| Item | Location after teardown |
|------|-------------------------|
| Git repo | GitHub — **kept** |
| Cosign public key | Git Kyverno policy — **kept** |
| Cosign private key | Key Vault — **destroyed** with KV |
| Signed images | ACR — **destroyed** |
| TF state (dev) | Bootstrap blob — **kept** unless bootstrap destroyed |

### Validation

- [ ] Public cosign key in Git
- [ ] ADO pipelines paused or accepted failures

---

## Step 13.2: Dry-run destroy plan

### Goal

Preview Terraform destroy scope without applying.

### Why this step is required

Confirms the correct subscription and resource group before irreversible deletion.

### Commands

```bash
cd /path/to/boutique-aks-devsecops
chmod +x scripts/operations/teardown.sh

./scripts/operations/teardown.sh --confirm destroy-boutique-platform --dry-run
```

Review plan output for:

- `azurerm_kubernetes_cluster`
- `azurerm_container_registry`
- `azurerm_key_vault`
- `azurerm_dns_zone`
- `azurerm_virtual_network`

(No Log Analytics workspace in default test — ADR-0012.)

### Validation

- [ ] Plan lists expected platform resources
- [ ] No unrelated production resources in same RG name

---

## Step 13.3: Execute platform teardown

### Goal

Destroy `terraform/environments/dev` stack.

### Why this step is required

Primary cost stop — removes AKS, ACR, ingress LB, and supporting Azure resources.

### Commands

```bash
./scripts/operations/teardown.sh --confirm destroy-boutique-platform
```

**Manual alternative:**

```bash
cd terraform/environments/dev
terraform init
terraform destroy
# Type 'yes' when prompted
```

**GUI cross-check:** Azure Portal → Resource groups → confirm platform RG deleting/ gone.

### Expected output

Script ends with:

```text
OK: platform resource group <name> not found (destroyed)
Remaining boutique AKS clusters: 0
Remaining boutique ACR registries: 0
```

### Validation

- [ ] `terraform destroy` completed without error
- [ ] Script verification messages OK

---

## Step 13.4: Verify Azure cleanup

### Goal

Confirm billable resources are gone.

### Why this step is required

Terraform success with leftover resources still incurs cost.

### Commands

```bash
RG="$(grep -E '^resource_group_name' terraform/environments/dev/terraform.tfvars | sed -E 's/.*=\s*"([^"]+)".*/\1/')"
az group exists --name "${RG}" && echo "FAIL: RG still exists" || echo "OK: RG gone"

az aks list --query "[].{name:name, rg:resourceGroup}" -o table
az acr list --query "[].{name:name, rg:resourceGroup}" -o table
az network public-ip list --query "[?contains(name, 'boutique') || contains(resourceGroup, 'boutique')]" -o table
```

Key Vault soft-delete:

```bash
KV="$(grep -E '^key_vault_name' terraform/environments/dev/terraform.tfvars | sed -E 's/.*=\s*"([^"]+)".*/\1/')"
az keyvault list-deleted --query "[?name=='${KV}']" -o table
```

Purge if you need the name for rebuild:

```bash
az keyvault purge --name "${KV}"
```

### Validation

- [ ] No platform resource group
- [ ] No project AKS cluster
- [ ] No project ACR (ADR-0010)
- [ ] Key Vault purged or soft-delete understood

---

## Step 13.5: DNS and registrar cleanup

### Goal

Update domain delegation if Azure DNS zone was removed.

### Why this step is required

Stale NS records at registrar point to deleted Azure nameservers.

### Commands

```bash
# If zone gone, registrar should remove Azure NS delegation for biroltilki.art
# Optional — verify external DNS no longer resolves to old ingress IP
dig NS biroltilki.art +short
dig +short dev-boutique.biroltilki.art
```

Remove Azure DNS **A records** are gone with zone destruction. If you **retained** DNS zone manually, delete A records for:

- `argocd-boutique`, `grafana-boutique`, `dev-boutique`, `stage-boutique`, `boutique`

### Validation

- [ ] Registrar NS delegation updated if zone destroyed
- [ ] Public hostnames no longer resolve (or expected NXDOMAIN)

---

## Step 13.6: Optional — destroy bootstrap state

### Goal

Remove Terraform remote state storage (bootstrap Topic 01).

### Why this step is required

Only when **fully decommissioning** the project — saves ~€1–2/month.

### Commands

```bash
./scripts/operations/teardown.sh --confirm destroy-boutique-platform --destroy-bootstrap
```

Or:

```bash
cd terraform/bootstrap
terraform destroy
```

### Validation

- [ ] Bootstrap RG + storage account removed (if chosen)
- [ ] Documented that full rebuild needs Topic 01 bootstrap again

---

## Step 13.7: Post-teardown documentation

### Goal

Record completion and rebuild path.

### Why this step is required

Future-you needs clear restart steps after ACR destruction.

### Rebuild order

```text
01 bootstrap → 02 foundation → 03 cluster → 04 OIDC → 05 GitOps → … → 09 mirror (required) → 10–12 apps
```

ACR images **must** be re-mirrored and re-signed after teardown.

### Commands

```bash
# Cost sanity check (may lag 24–48h)
az consumption usage list \
  --start-date $(date -u -v-7d +%Y-%m-%d 2>/dev/null || date -u -d '7 days ago' +%Y-%m-%d) \
  --end-date $(date -u +%Y-%m-%d) -o table 2>/dev/null | head -20 || true
```

Update [Setup Index](README.md) Topic 13 to ✅ when complete.

### Validation

- [ ] Teardown checklist in [teardown.md](../runbooks/teardown.md) reviewed
- [ ] [threat-model.md](../security/threat-model.md) archived for project record

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Destroy timeout on AKS | Wait; retry `terraform destroy` |
| RG not empty | `az resource list -g <rg>` — delete stragglers |
| KV name blocked | `az keyvault purge --name <kv>` |
| State lock | Break blob lease on `tfstate` container |
| Bootstrap destroy fails | Destroy dev environment first |

Full reference: [teardown.md](../runbooks/teardown.md)

---

## Topic complete checklist

- [ ] `teardown.sh --dry-run` reviewed
- [ ] Platform `terraform destroy` succeeded
- [ ] No AKS / ACR / platform RG in subscription
- [ ] DNS/registrar updated if needed
- [ ] Bootstrap retained **or** intentionally destroyed
- [ ] Rebuild path understood (Topic 09 mirror required)

---

## Setup guide complete

**All Topics 00–13** are authored. Phase C execution is complete when you confirm this teardown (or document intentional skip while keeping test running).

### Phase D — readiness validation (next)

When ready for end-to-end project validation:

1. Re-run integration smokes if test still running **before** teardown
2. Confirm Required Files Inventory satisfied per topic
3. Request Phase D validation in Setup Chat

**Phase D phrase:** `Begin Setup Phase D — readiness validation`

---

## Security artifacts (Topic 13)

| Document | Path |
|----------|------|
| Threat model | [threat-model.md](../security/threat-model.md) |
| Incident response | [incident-response.md](../runbooks/incident-response.md) |
| Teardown runbook | [teardown.md](../runbooks/teardown.md) |
