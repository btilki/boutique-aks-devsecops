# 03 — Cluster Resources (AKS, ACR, Key Vault)

**Audience:** L2 — Implementer
**Estimated time:** 120 minutes (AKS create ~15–20 min)
**Prerequisites:** [02-azure-foundation.md](02-azure-foundation.md) ✅ complete
**Creates:** AKS cluster (WI + OIDC), ACR, Key Vault, platform UAMI, RBAC (AcrPull, KV Secrets User, DNS Zone Contributor)
**Related ADRs:** [0002](../adr/0002-single-cluster-multi-namespace.md), [0011](../adr/0011-aks-node-vm-sku.md)

---

## Topic goal

When this topic is complete, a production-pilot **AKS cluster** runs in `germanywestcentral` with system (`Standard_D2s_v6`) and user (`Standard_D4s_v6`) node pools, an **ACR** registry for signed images, a **Key Vault** for platform secrets, and **identity wiring** so kubelet can pull from ACR and the platform UAMI can read Key Vault secrets and manage DNS records for cert-manager.

## Why this topic is required

GitOps (Topic 05), CI (Topic 09), and Kyverno (Topic 08) all assume a live cluster and private registry. Workload Identity and OIDC issuer must exist before ADO federation (Topic 04) and cert-manager DNS-01 (Topic 06). Applying cluster resources as a separate topic keeps Topic 02 networking stable and makes AKS failures easier to diagnose.

---

## Before you begin

- [ ] Topic 02 applied: `terraform output aks_subnet_id` is non-empty
- [ ] DNS delegation in progress or complete (not blocking AKS, but needed before Topic 06)
- [ ] `az vm list-skus` still shows D2s_v6 / D4s_v6 available (see [00-prerequisites.md](00-prerequisites.md))
- [ ] You accept **AKS + nodes** monthly cost (~€100–200 order-of-magnitude)

```bash
cd terraform/environments/dev
terraform output aks_subnet_id
az vm list-skus --location germanywestcentral --size Standard_D4s_v6 --all -o table | head -5
```

---

## Step 3.1: Review Topic 03 Terraform additions

### Goal

Understand new modules and naming before `plan`.

### Why this step is required

ACR and Key Vault names are globally unique. AKS subnet cannot change after cluster creation.

### Commands

```bash
cd /path/to/boutique-aks-devsecops
grep -E '^module "(acr|key_vault|aks|identities)"' terraform/environments/dev/main.tf
cat terraform/environments/dev/terraform.tfvars.example | tail -20
```

### Expected output

Four new modules wired after Topic 02 modules. Example names:

| Resource | Example name |
|----------|--------------|
| AKS | `aks-boutique-dev-gwc` |
| ACR | `acrboutiquedevgwc` |
| Key Vault | `kv-boutique-dev-gwc` |
| Platform UAMI | `uami-boutique-platform` |

### Validation

- [ ] `main.tf` includes `module.aks` using `module.networking.aks_subnet_id`
- [ ] `module.identities` references ACR, Key Vault, DNS zone, kubelet identity

---

## Step 3.2: Update terraform.tfvars for Topic 03

### Goal

Add ACR, Key Vault, and AKS names to your local tfvars.

### Why this step is required

ACR name must be globally unique; Key Vault name must be unique in Azure.

### Commands

```bash
cd terraform/environments/dev
```

Add to `terraform.tfvars` (from `terraform.tfvars.example`):

```hcl
acr_name       = "acrboutiquedevgwc"   # change if taken
key_vault_name = "kv-boutique-dev-gwc" # change if taken
aks_cluster_name = "aks-boutique-dev-gwc"
```

**ACR name check:**

```bash
az acr check-name --name acrboutiquedevgwc
```

**Key Vault name check:**

```bash
az keyvault list-deleted --query "[?name=='kv-boutique-dev-gwc']" -o table
```

If soft-deleted, purge or choose a new name.

### Validation

- [ ] `acr check-name` shows `nameAvailable: true` (or you picked another name)
- [ ] VM SKUs unchanged from `versions.yaml`

---

## Step 3.3: Plan cluster resources

### Goal

Preview AKS, ACR, Key Vault, diagnostics, and role assignments.

### Why this step is required

Largest `plan` so far — verify resource count and no unexpected destroys of Topic 02 resources.

### Commands

```bash
cd terraform/environments/dev
terraform init -input=false -upgrade
terraform plan -input=false -out=tfplan
```

### Expected output

Plan adds approximately **15–20 resources**, including:

- `azurerm_kubernetes_cluster`
- `azurerm_kubernetes_cluster_node_pool.user`
- `azurerm_container_registry`
- `azurerm_key_vault`
- `azurerm_user_assigned_identity.platform`
- Multiple `azurerm_role_assignment`
- `azurerm_monitor_diagnostic_setting` (AKS, ACR, KV)

**No destroys** of Topic 02 VNet/DNS unless you changed addressing.

### Validation

- [ ] Plan shows 2 node pools (system + user)
- [ ] `kubernetes_version` = `1.34` (or current supported minor per `az aks get-versions`)
- [ ] `workload_identity_enabled` / OIDC implied in cluster resource
- [ ] System pool `Standard_D2s_v6`, user pool `Standard_D4s_v6` (see ADR-0011)

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| SKU unavailable | Capacity / restriction | Re-check `az vm list-skus`; see ADR-0011 |
| ACR name taken | Global collision | Change `acr_name` in tfvars |
| Role assignment error on plan | Rare provider issue | Ensure Owner/User Access Admin for RBAC assignments |

### Cost impact

⚠️ **AKS control plane + 2 nodes** — primary monthly cost begins here.

---

## Step 3.4: Apply cluster resources

### Goal

Create AKS, ACR, Key Vault, and identity RBAC in Azure.

### Why this step is required

All platform topics from GitOps onward need these resources.

### Commands

```bash
cd terraform/environments/dev
terraform apply -input=false tfplan
```

**Expected duration:** 15–25 minutes (AKS provisioning is slow).

### Expected output

```text
Apply complete! Resources: N added, 0 changed, 0 destroyed.
```

Capture outputs:

```bash
terraform output
```

### Validation

- [ ] Apply exits 0
- [ ] `terraform output aks_oidc_issuer_url` is a valid HTTPS URL
- [ ] `terraform output acr_login_server` ends with `.azurecr.io`

### Recovery

If apply fails on role assignment after partial create:

```bash
terraform plan -input=false
terraform apply -input=false
```

Do **not** manually delete the MC_* node resource group — let Terraform reconcile.

---

## Step 3.5: Configure kubectl and verify nodes

### Goal

Connect to the cluster and confirm both node pools are Ready.

### Why this step is required

Proves API server reachable and node pools registered before GitOps.

### Commands

```bash
cd terraform/environments/dev
RG=$(terraform output -raw resource_group_name)
CLUSTER=$(terraform output -raw aks_cluster_name)

az aks get-credentials --resource-group "${RG}" --name "${CLUSTER}" --overwrite-existing
kubectl get nodes -o wide
kubectl get nodes --show-labels | grep agentpool
```

### Expected output

Two nodes in `Ready` state:

- `agentpool=system` — `Standard_D2s_v6`
- `agentpool=user` — `Standard_D4s_v6`

### Validation

```bash
kubectl cluster-info
kubectl get pods -A | head -20
```

- [ ] `kubectl get nodes` shows 2 Ready nodes
- [ ] System pods in `kube-system` are Running (may take 2–5 min after apply)

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `kubectl` unauthorized | AAD RBAC not propagated | Assign yourself **Azure Kubernetes Service RBAC Cluster Admin** on the cluster (GUI below) |
| Nodes NotReady | CNI starting | Wait 5 minutes; check `kubectl describe node` |
| Wrong context | Old kubeconfig | Re-run `az aks get-credentials --overwrite-existing` |

### GUI — grant yourself cluster admin (if needed)

1. Navigate to: **Azure Portal** → **Kubernetes services** → **`aks-boutique-dev-gwc`**
2. Click **Access control (IAM)** → **Add role assignment**
3. Role: **Azure Kubernetes Service RBAC Cluster Admin**
4. Member: your user account
5. Save; wait 1–5 minutes; retry `kubectl get nodes`

---

## Step 3.6: Verify ACR access

### Goal

Confirm you can authenticate to ACR and kubelet has AcrPull (pull test after first push in Topic 09).

### Why this step is required

CI and Kyverno assume images live in this registry only.

### Commands

```bash
ACR_NAME=$(cd terraform/environments/dev && terraform output -raw acr_name)
az acr show --name "${ACR_NAME}" --query "{loginServer:loginServer, sku:sku.name}" -o json
az acr login --name "${ACR_NAME}"
az acr repository list --name "${ACR_NAME}" -o table
```

### Expected output

Login succeeds; repository list is empty (no images mirrored yet).

**Optional push smoke test:**

```bash
docker pull mcr.microsoft.com/azure-cli:latest
docker tag mcr.microsoft.com/azure-cli:latest "${ACR_NAME}.azurecr.io/smoke/azure-cli:test"
docker push "${ACR_NAME}.azurecr.io/smoke/azure-cli:test"
az acr repository show-tags --name "${ACR_NAME}" --repository smoke/azure-cli -o table
```

### Validation

- [ ] `az acr login` succeeds
- [ ] `admin_enabled` is false (no admin user)

### Security notes

- Images must be signed before Kyverno allows them in Topic 08+ (except test policies)

---

## Step 3.7: Verify Key Vault

### Goal

Confirm Key Vault exists with RBAC authorization enabled.

### Why this step is required

cosign keys and Grafana secrets land here in later topics.

### Commands

```bash
KV_NAME=$(cd terraform/environments/dev && terraform output -raw key_vault_name)
RG=$(cd terraform/environments/dev && terraform output -raw resource_group_name)

az keyvault show --name "${KV_NAME}" --resource-group "${RG}" \
  --query "{name:name, enableRbac:properties.enableRbacAuthorization, uri:properties.vaultUri}" -o json
```

### Expected output

```json
{
  "enableRbac": true,
  "name": "kv-boutique-dev-gwc",
  "uri": "https://kv-boutique-dev-gwc.vault.azure.net/"
}
```

### Validation

- [ ] RBAC authorization enabled
- [ ] You can list secrets (empty is OK):

```bash
az keyvault secret list --vault-name "${KV_NAME}" -o table
```

Requires **Key Vault Administrator** or **Secrets Officer** (Terraform grants deployer Administrator on create).

---

## Step 3.8: Run post-apply validation script

### Goal

Run automated smoke checks for Topic 03.

### Why this step is required

Single command replay for workshops and CI local gates.

### Commands

```bash
cd /path/to/boutique-aks-devsecops
chmod +x tests/terraform/foundation-post-apply.sh
./tests/terraform/foundation-post-apply.sh
```

Also run:

```bash
./tests/terraform/validate.sh
```

### Expected output

```text
[post-apply] kubectl get nodes
NAME                             STATUS   ROLES    ...
[post-apply] OK
[validate] OK
```

### Validation

- [ ] Both scripts exit 0

---

## Topic validation (end-to-end)

```bash
cd terraform/environments/dev
terraform output aks_oidc_issuer_url
kubectl get nodes
az acr show -n $(terraform output -raw acr_name) --query name -o tsv
./../../tests/terraform/foundation-post-apply.sh
```

**Success criteria:**

- [ ] AKS cluster Running with 2 node pools
- [ ] ACR reachable via `az acr login`
- [ ] Key Vault RBAC enabled
- [ ] `aks_oidc_issuer_url` captured for Topic 04
- [ ] `platform_identity_client_id` output available for Topic 06/07

Update [Setup Index](README.md) Topic 03 to ✅ when complete.

---

## Topic troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| AKS create timeout | Azure capacity | Retry apply; try off-peak hours |
| `InsufficientSubnetSize` | Subnet too small | `/20` should suffice; do not shrink |
| Key Vault name in soft-delete | Prior test | `az keyvault purge` or new name |
| OIDC URL empty | Cluster not finished | Wait; re-run `terraform output` |

---

## Next step

➡️ Continue to **[04-ado-oidc.md](04-ado-oidc.md)** (Topic 04) after Topic 03 validation.

Topic 04 uses `aks_oidc_issuer_url` and subscription context for ADO workload identity federation.
