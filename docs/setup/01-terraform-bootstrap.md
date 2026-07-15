# 01 — Terraform Bootstrap

**Audience:** L2 — Implementer
**Estimated time:** 60 minutes
**Prerequisites:** [00-prerequisites.md](00-prerequisites.md) ✅ complete
**Creates:** Azure resource group + storage account + blob container for remote Terraform state; `terraform/environments/dev/` remote backend configuration
**Related ADRs:** — (foundation for [FR-01](../../ARCHITECTURE.md))

---

## Topic goal

When this topic is complete, Azure hosts a dedicated **remote state backend** (resource group, storage account, private container), and `terraform/environments/dev/` successfully runs `terraform init` against that backend. The bootstrap stack itself remains on **local state** — only the platform stack uses remote state.

## Why this topic is required

Terraform state contains resource IDs, dependencies, and secrets metadata. Local state files are easy to lose, impossible to share safely, and block team workflows. Remote state in Azure Blob Storage with versioning enabled gives durable, recoverable state before any AKS or networking resources are created in Topic 02.

Without this topic, `environments/dev/` cannot persist state across machines or survive laptop loss.

---

## Before you begin

- [ ] [00-prerequisites.md](00-prerequisites.md) validation checklist complete
- [ ] `az account show` returns the intended subscription
- [ ] You have **Contributor** or **Owner** on the subscription (to create storage account)
- [ ] You chose a **globally unique** `storage_account_name` (see Step 1.2)

```bash
az account show --query "{subscription:id, tenant:tenantId}" -o json
terraform version
```

---

## Step 1.1: Review bootstrap module and naming

### Goal

Understand what the bootstrap stack creates and confirm naming before any `apply`.

### Why this step is required

Storage account names are globally unique and immutable. A failed apply due to name collision wastes time; wrong names in `backend.tf` break `environments/dev` init.

### Commands

```bash
cd /path/to/boutique-aks-devsecops
ls -la terraform/bootstrap/
cat terraform/bootstrap/terraform.tfvars.example
```

### Expected output

Files present: `main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`.

Example tfvars shows:

- `location = "germanywestcentral"`
- `state_resource_group_name = "rg-tfstate-boutique-gwc"`
- `storage_account_name = "stboutiquetfgwc"` (you may need to change this)

### Validation

- [ ] You understand bootstrap creates **3 Azure resources** (RG, storage account, container)
- [ ] Bootstrap uses **local state** in `terraform/bootstrap/terraform.tfstate` (created on first apply)
- [ ] Platform resources are **not** created in this topic

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Directory empty | Topic 01 files not materialized | Re-run Phase B Topic 01 delivery |
| Confusion about two state files | Bootstrap vs dev backend | Bootstrap = local; dev = remote blob `dev.terraform.tfstate` |

### Recovery

No Azure resources yet — safe to re-read and continue.

### Security notes

- State storage will hold platform resource metadata — keep container **private** (default in module)
- Do not commit `terraform.tfvars` — it is gitignored

---

## Step 1.2: Create bootstrap terraform.tfvars

### Goal

Create your local `terraform.tfvars` with a unique storage account name.

### Why this step is required

Terraform needs your chosen names at plan/apply time. The example file is committed; real values stay local.

### Commands

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

1. Set `storage_account_name` to a **globally unique** value (3–24 chars, lowercase letters and numbers only).
2. Optionally set `owner` tag in `tags`.

**Name availability check (optional):**

```bash
az storage account check-name --name "<YOUR_STORAGE_ACCOUNT_NAME>"
```

### Expected output

`check-name` returns `"nameAvailable": true` if the name is free.

### Validation

- [ ] `terraform.tfvars` exists and is **not** staged for Git (`git status` should not show it)
- [ ] `storage_account_name` matches `^[a-z0-9]{3,24}$`

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `NameAlreadyTaken` on apply | Storage name in use globally | Pick another name; update `terraform.tfvars` and `environments/dev/backend.tf` |
| Invalid name | Uppercase or hyphens | Use lowercase alphanumeric only |

### Recovery

Edit `terraform.tfvars` before apply — no Azure changes yet.

---

## Step 1.3: Initialize bootstrap Terraform

### Goal

Download providers and initialize the bootstrap working directory.

### Why this step is required

`terraform plan/apply` require provider plugins and a initialized backend (local default).

### Commands

```bash
cd terraform/bootstrap
terraform init -input=false
```

### Expected output

```text
Terraform has been successfully initialized!
```

Provider: `hashicorp/azurerm` version matching `~> 3.100`.

### Validation

```bash
terraform version
ls .terraform/providers/
```

- [ ] Init exits 0
- [ ] `.terraform/` directory created (gitignored)

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Provider download failed | Network/proxy | Retry; check corporate proxy |
| Version constraint error | Old Terraform CLI | Upgrade to >= 1.6.0 per [versions.yaml](../../versions.yaml) |

### Recovery

`rm -rf .terraform` and re-run `terraform init` if provider cache corrupt.

---

## Step 1.4: Plan bootstrap apply

### Goal

Preview Azure resources before creation.

### Why this step is required

Confirms correct subscription, region, and names without creating billable resources.

### Commands

```bash
cd terraform/bootstrap
terraform plan -input=false -out=tfplan
```

### Expected output

Plan shows **3 to add**:

- `azurerm_resource_group.state`
- `azurerm_storage_account.state`
- `azurerm_storage_container.state`

No destroy or change on first run.

### Validation

- [ ] Plan summary: `Plan: 3 to add, 0 to change, 0 to destroy`
- [ ] Location is `germanywestcentral`
- [ ] Storage account name matches your `terraform.tfvars`

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Wrong subscription in plan | Azure CLI context | `az account set --subscription "<ID>"` |
| Authorization failed | Insufficient RBAC | Request Contributor on subscription |

### Recovery

No resources created — fix variables and re-plan.

### Security notes

- Review plan output for unexpected resources
- **Cost:** storage account LRS is low cost (~€1–5/month) but not free

---

## Step 1.5: Apply bootstrap stack

### Goal

Create the remote state backend in Azure.

### Why this step is required

`environments/dev/` remote backend cannot initialize until the container exists.

### Commands

```bash
cd terraform/bootstrap
terraform apply -input=false tfplan
```

Or interactively:

```bash
terraform apply -input=false
```

Type `yes` when prompted.

### Expected output

```text
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

backend_config = { ... }
container_name = "tfstate"
state_resource_group_name = "rg-tfstate-boutique-gwc"
storage_account_name = "stboutiquetfgwc"
```

### Validation

```bash
terraform output -json
```

- [ ] Apply exits 0
- [ ] `terraform.tfstate` exists locally in `terraform/bootstrap/` (gitignored)

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `StorageAccountAlreadyTaken` | Name not unique | Change name in tfvars; taint not needed if apply failed completely |
| `AuthorizationFailed` | RBAC | Confirm Contributor role |
| Apply hangs | Azure API delay | Wait up to 2–3 minutes |

### Recovery

If apply partially failed:

```bash
terraform plan -input=false
terraform apply -input=false
```

Terraform reconciles to desired state. To destroy bootstrap only (⚠️ destroys state storage):

```bash
terraform destroy -input=false
```

Only run destroy if no `environments/dev` state has been written yet.

### Best practices

- Enable blob versioning (already in module) — aids state recovery
- Keep bootstrap RG separate from platform RG (`rg-boutique-dev-gwc` in Topic 02)

---

## Step 1.6: Verify storage in Azure Portal

### Goal

Confirm the state container exists and is private.

### Why this step is required

Visual confirmation catches wrong-subscription mistakes before wiring dev backend.

### GUI instructions

1. Navigate to: **Azure Portal** → **Resource groups** → **`rg-tfstate-boutique-gwc`** (or your `state_resource_group_name`)
2. Click the **storage account** resource
3. Under **Data storage**, click **Containers**
4. Confirm container **`tfstate`** exists with **Access level: Private**

| Field | Expected value | Notes |
|-------|----------------|-------|
| Resource group | `rg-tfstate-boutique-gwc` | State-only RG |
| Location | Germany West Central | Matches `versions.yaml` |
| Container | `tfstate` | Private access |
| Versioning | Enabled | On blob service |

### CLI validation

```bash
az storage container exists \
  --account-name "<YOUR_STORAGE_ACCOUNT_NAME>" \
  --name tfstate \
  --auth-mode login
```

### Expected output

```json
true
```

### Validation

- [ ] Container exists
- [ ] Container is empty (no `dev.terraform.tfstate` blob until Topic 02 init/apply)

---

## Step 1.7: Align dev backend configuration

### Goal

Ensure `terraform/environments/dev/backend.tf` literals match bootstrap outputs.

### Why this step is required

Backend blocks cannot use variables. Mismatched names cause `terraform init` failure in Topic 02.

### Commands

```bash
cd terraform/bootstrap
terraform output -json backend_config
```

Compare with `terraform/environments/dev/backend.tf`.

If you used **different** names in `terraform.tfvars`, edit `backend.tf` to match outputs:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "<from output>"
    storage_account_name = "<from output>"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
```

### Validation

- [ ] `resource_group_name` matches `terraform output state_resource_group_name`
- [ ] `storage_account_name` matches `terraform output storage_account_name`
- [ ] `key` is `dev.terraform.tfstate`

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Edited backend.tf but wrong storage name | Copy-paste error | Re-run `terraform output` |

---

## Step 1.8: Initialize dev environment remote backend

### Goal

Verify `environments/dev/` connects to the new remote backend (no platform apply yet).

### Why this step is required

Proves end-to-end backend wiring before Topic 02 adds `main.tf` and modules.

### Commands

```bash
cd terraform/environments/dev
terraform init -input=false
```

### Expected output

```text
Successfully configured the backend "azurerm"!
Terraform has been successfully initialized!
```

If prompted to copy local state to backend, answer **no** — there is no prior dev state.

### Validation

```bash
terraform init -input=false 2>&1 | tail -5
```

- [ ] Init exits 0
- [ ] No error about missing container or auth

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `403 Authorization` on backend | RBAC on storage | Ensure your user has **Storage Blob Data Contributor** on the storage account, or use account key (not recommended). Easiest fix: assign **Contributor** on the state RG. |
| `ContainerNotFound` | Bootstrap apply incomplete | Re-run Step 1.5 |
| Backend config mismatch | Wrong literals in `backend.tf` | Fix Step 1.7 |

**RBAC fix (GUI):**

1. Navigate to: **Storage account** → **Access control (IAM)** → **Add role assignment**
2. Role: **Storage Blob Data Contributor**
3. Member: your user account
4. Save and wait 1–2 minutes for propagation

### Recovery

`rm -rf .terraform` in `environments/dev` and re-run `terraform init`.

### Security notes

- Prefer Azure AD auth (`--auth-mode login`) over storage account keys
- State blob will contain platform secrets metadata after Topic 02+

---

## Topic validation (end-to-end)

Run before marking Topic 01 complete:

```bash
# Bootstrap outputs
cd terraform/bootstrap && terraform output

# Container exists
az storage container exists \
  --account-name "$(terraform output -raw storage_account_name)" \
  --name "$(terraform output -raw container_name)" \
  --auth-mode login

# Dev backend init
cd ../environments/dev && terraform init -input=false
```

**Success criteria:**

- [ ] Bootstrap `terraform output` shows all three values
- [ ] Container exists (`true`)
- [ ] `environments/dev` `terraform init` succeeds
- [ ] `terraform validate` in `environments/dev` may warn **no configuration files** until Topic 02 — that is expected

Update [Setup Index](README.md) Topic 01 status to ✅ when complete.

---

## Topic troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Two different storage accounts | Re-ran bootstrap with new name | Pick one; update `backend.tf`; migrate state if needed |
| Lost bootstrap local state | Deleted `terraform/bootstrap/terraform.tfstate` | Import existing resources or destroy via Portal and re-apply |
| Cannot destroy bootstrap in teardown | Dev state still in container | Run Topic 13 dev destroy first |

---

## Next step

➡️ Continue to **[02-azure-foundation.md](02-azure-foundation.md)** (Topic 02) after you confirm Topic 01 validation.

Do not run `terraform apply` in `environments/dev/` until Topic 02 guide and files are ready.
