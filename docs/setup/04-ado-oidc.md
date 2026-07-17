# 04 — ADO OIDC Federation

**Audience:** L2 — Implementer
**Estimated time:** 75 minutes
**Prerequisites:** [03-cluster-resources.md](03-cluster-resources.md) ✅ complete
**Creates:** Pipeline UAMI, federated identity credential, AcrPush + Key Vault Secrets User RBAC; ADO ARM service connection (GUI)
**Related ADRs:** [0008](../adr/0008-ado-prod-approval-gate.md) (trust foundation for CI gates)

---

## Topic goal

When this topic is complete, **Azure DevOps pipelines** authenticate to Azure using **OIDC workload identity federation** — no client secrets or PATs in service connections. The pipeline identity can **push to ACR** and **read secrets from Key Vault** (cosign key in Topic 09).

## Why this topic is required

Long-lived secrets in CI are a top supply-chain risk. OIDC federation issues short-lived tokens per job. Topic 09 mirror/scan/sign pipeline depends on this service connection. The federation `subject` must match the ADO service connection name exactly.

---

## Before you begin

- [ ] Topic 03 applied: AKS, ACR, Key Vault exist
- [ ] Azure DevOps **organization** and **project** created (or use existing)
- [ ] Permission to create **service connections** in the ADO project
- [ ] Permission to create **federated credentials** (via Terraform Contributor on subscription)

Gather ADO organization GUID:

```bash
# Replace <ADO_ORG_NAME> with your organization slug from dev.azure.com/<ADO_ORG_NAME>
az devops user show --organization "https://dev.azure.com/<ADO_ORG_NAME>" 2>/dev/null || true
```

**Organization ID (GUID):** Azure DevOps → **Organization settings** → **Overview** → copy **Organization ID**.

---

## Step 4.1: Review federation module

### Goal

Understand Terraform-created identity and federation subject format.

### Why this step is required

A single typo in `ado_organization_name` or `service_connection_name` causes `AADSTS700213` at pipeline runtime.

### Commands

```bash
cd /path/to/boutique-aks-devsecops
cat terraform/modules/ado-federation/main.tf
cat terraform/environments/dev/terraform.tfvars.example | tail -10
```

### Expected output

Federation subject pattern (Entra issuer — current ADO default):

```text
Issuer:  https://login.microsoftonline.com/{tenant-id}/v2.0
Subject: sc://{organization}/{project}/{service-connection-name}
```

Legacy issuer `https://vstoken.dev.azure.com/{org-id}` is deprecated (retired July 2027).

Default service connection name: `azure-boutique-oidc`

### Validation

- [ ] You have your ADO **organization GUID**, **org name**, and **project name** ready

---

## Step 4.2: Add ADO variables to terraform.tfvars

### Goal

Configure federation subject components in local tfvars.

### Why this step is required

Organization GUID drives the OIDC issuer URL; names must match ADO exactly.

### Commands

```bash
cd terraform/environments/dev
```

Add to `terraform.tfvars`:

```hcl
ado_organization_id   = "<YOUR-ADO-ORG-GUID>"
ado_organization_name = "<ADO_ORG_NAME>"
ado_project_name      = "boutique-aks-devsecops"
ado_service_connection_name = "azure-boutique-oidc"
```

### Validation

- [ ] `ado_organization_id` is a valid GUID (36 characters)
- [ ] `ado_organization_name` matches URL path on `dev.azure.com`
- [ ] `ado_service_connection_name` has no spaces (use hyphens)

---

## Step 4.3: Plan and apply federation

### Goal

Create pipeline UAMI, federated credential, and RBAC assignments.

### Why this step is required

Azure side of trust must exist before ADO service connection creation.

### Commands

```bash
cd terraform/environments/dev
terraform init -input=false
terraform plan -input=false -out=tfplan
terraform apply -input=false tfplan
terraform output ado_oidc_subject
terraform output ado_pipeline_identity_client_id
```

### Expected output

Plan adds approximately **4–5 resources**:

- `azurerm_user_assigned_identity.pipeline`
- `azurerm_federated_identity_credential.ado`
- `azurerm_role_assignment` (AcrPush, Key Vault Secrets User)

### Validation

- [ ] Apply exits 0
- [ ] `ado_oidc_issuer` starts with `https://login.microsoftonline.com/` and ends with `/v2.0`
- [ ] `ado_oidc_subject` matches `sc://{org}/{project}/azure-boutique-oidc`

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Invalid GUID | Wrong org ID | Re-copy from ADO Organization settings |
| Role assignment failed | Insufficient RBAC | Need User Access Administrator or Owner to assign roles |

---

## Step 4.4: Create ADO ARM service connection (GUI)

### Goal

Register the workload identity federation in Azure DevOps.

### Why this step is required

ADO must know which Azure identity to request tokens for.

### Commands

Print field values:

```bash
cd /path/to/boutique-aks-devsecops
chmod +x scripts/register-ado-sc-federation.sh
./scripts/register-ado-sc-federation.sh
```

### GUI instructions

**Platform:** Azure DevOps
**Permissions:** Project Administrator or equivalent to create service connections

1. Navigate to: **`https://dev.azure.com/<ADO_ORG_NAME>/<ADO_PROJECT_NAME>`** → **Project settings** (bottom left) → **Service connections**
2. Click **New service connection** → **Azure Resource Manager** → **Next**
3. Select **Workload Identity federation (manual)** → **Next**
4. Fill fields:

| Field | Value | Notes |
|-------|-------|-------|
| Service connection name | `azure-boutique-oidc` | **Must match** `ado_service_connection_name` in tfvars |
| Subscription ID | From `terraform output azure_subscription_id` | Your test subscription |
| Subscription name | Select from dropdown | Display only |
| Resource group | `rg-boutique-dev-gwc` | Scopes connection visibility |
| Managed identity client ID | `terraform output -raw ado_pipeline_identity_client_id` | Pipeline UAMI — not platform UAMI |
| Tenant ID | `terraform output -raw azure_tenant_id` | Entra tenant |

5. Check **Grant access permission to all pipelines** (or authorize per pipeline later)
6. Click **Save**

**Verification:** Service connection list shows `azure-boutique-oidc` with green check; no secret fields configured.

### Security notes

- No client secret should appear — if prompted for secret, wrong authentication method selected
- Scope to platform resource group where possible

---

## Step 4.5: Verify federation in Azure

### Goal

Confirm federated credential and RBAC exist in Azure.

### Why this step is required

Catches Terraform/ADO drift before pipeline debugging.

### Commands

```bash
chmod +x scripts/verify-oidc-trust.sh
./scripts/verify-oidc-trust.sh
```

### Expected output

- Identity `uami-ado-pipeline` listed
- Federated credential shows matching issuer and subject
- AcrPush and Key Vault Secrets User (OK or WARN during propagation)

### Validation

- [ ] Issuer and subject in Azure match `terraform output`
- [ ] No ERROR lines from verify script

---

## Step 4.6: Run OIDC test pipeline

### Goal

Prove the service connection acquires an Azure token in a pipeline job.

### Why this step is required

End-to-end validation of federation before Topic 09 CI work.

### GUI instructions — create test pipeline

1. Navigate to: **Pipelines** → **New pipeline** → select your repo → **Existing Azure Pipelines YAML file** (or create minimal YAML below)
2. Use this test `azure-pipelines-oidc-test.yml` content in repo (optional file for test only):

```yaml
trigger: none

pool:
  vmImage: ubuntu-latest

steps:
  - task: AzureCLI@2
    displayName: OIDC trust smoke test
    inputs:
      azureSubscription: azure-boutique-oidc
      scriptType: bash
      scriptLocation: inlineScript
      inlineScript: |
        set -euo pipefail
        echo "=== Azure account ==="
        az account show --query "{name:name, id:id, tenant:tenantId}" -o table
        echo "=== ACR login server ==="
        az acr list --query "[?contains(name, 'boutique')].loginServer" -o tsv
        echo "OIDC test passed"
```

3. **Run pipeline** manually
4. Confirm step **OIDC trust smoke test** succeeds

### Expected output

Pipeline log shows subscription name and tenant; exit code 0.

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `AADSTS700213` | Subject mismatch | See [ado-oidc.md](../troubleshooting/ado-oidc.md) |
| Service connection not authorized | Pipeline permissions | SC → Security → allow pipeline |
| `az: not logged in` | Wrong task config | Use `AzureCLI@2` with `azureSubscription` input |

---

## Topic validation (end-to-end)

```bash
cd terraform/environments/dev
terraform output ado_oidc_subject
./../../scripts/verify-oidc-trust.sh
```

- [ ] Terraform federation outputs populated
- [ ] ADO service connection `azure-boutique-oidc` exists
- [ ] Test pipeline `az account show` succeeds
- [ ] No client secrets in service connection

Update [Setup Index](README.md) Topic 04 to ✅ when complete.

---

## Topic troubleshooting

See [docs/troubleshooting/ado-oidc.md](../troubleshooting/ado-oidc.md).

---

## Next step

➡️ Continue to **[05-gitops-bootstrap.md](05-gitops-bootstrap.md)** (Topic 05).

GitOps bootstrap can proceed in parallel after Topic 03, but complete Topic 04 before Topic 09 CI pipeline.
