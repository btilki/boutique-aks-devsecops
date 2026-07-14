# ADO OIDC troubleshooting

Symptoms and fixes for Azure DevOps workload identity federation with Azure.

## Federation subject mismatch

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `AADSTS700213` / subject mismatch | Service connection name differs from Terraform `subject` | Rename SC to match `terraform output -raw ado_oidc_subject` or update tfvars and re-apply |
| Wrong organization in subject | `ado_organization_name` typo | Must match ADO URL `dev.azure.com/{org}` exactly (case-sensitive) |
| Wrong project in subject | `ado_project_name` typo | Match project name in ADO project settings |

Verify:

```bash
cd terraform/environments/dev
terraform output -raw ado_oidc_subject
# Expected format: sc://{org}/{project}/{service-connection-name}
```

## Issuer mismatch

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Invalid issuer | Wrong organization **GUID** | Use organization ID from ADO Organization settings → Overview, not display name |
| Issuer URL typo | Manual federated cred | Issuer must be `https://vstoken.dev.azure.com/{organization-guid}` |

```bash
terraform output -raw ado_oidc_issuer
```

## Service connection authorization

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Pipeline cannot use connection | Not authorized for pipeline | SC → ⋮ → Security → grant pipeline access |
| `Could not find service connection` | Wrong project | Create SC in same project as pipeline YAML |

## RBAC propagation

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `Authorization failed` on `az acr push` | AcrPush not propagated | Wait 5 min; re-run `scripts/verify-oidc-trust.sh` |
| Key Vault access denied | Secrets User missing | Confirm role on vault scope for pipeline UAMI client ID |

## Client ID confusion

Use **pipeline UAMI client ID**, not cluster or platform identity:

```bash
terraform output -raw ado_pipeline_identity_client_id
```

Do **not** use `platform_identity_client_id` for the ADO ARM service connection.

## Test pipeline snippet

```yaml
trigger: none
pool:
  vmImage: ubuntu-latest
steps:
  - task: AzureCLI@2
    displayName: OIDC smoke test
    inputs:
      azureSubscription: azure-boutique-oidc
      scriptType: bash
      scriptLocation: inlineScript
      inlineScript: |
        set -euo pipefail
        az account show -o table
        az acr show -n $(az acr list --query "[0].name" -o tsv) --query loginServer -o tsv
```

## Related

- [docs/setup/04-ado-oidc.md](../setup/04-ado-oidc.md)
- [scripts/verify-oidc-trust.sh](../../scripts/verify-oidc-trust.sh)
- [scripts/register-ado-sc-federation.sh](../../scripts/register-ado-sc-federation.sh)
