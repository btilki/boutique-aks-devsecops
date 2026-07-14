# Module: ado-federation

## Purpose

Entra app registration and federated credential for ADO OIDC.

## Inputs

Documented in `variables.tf` (Phase 2–4). See `terraform.tfvars.example` in environment root.

## Outputs

Documented in `outputs.tf`. Consumed by environment root, GitOps docs, or ADO setup.

## Dependencies

See [docs/implementation/plan.md](../../../docs/implementation/plan.md) for phase ordering.

## Usage

```hcl
module "ado_federation" {
  source = "../../modules/ado-federation"

  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  ado_organization_id   = var.ado_organization_id
  ado_organization_name   = var.ado_organization_name
  ado_project_name        = var.ado_project_name
  service_connection_name = "azure-boutique-oidc"
  acr_id                  = module.acr.id
  key_vault_id            = module.key_vault.id
}
```

Full steps: [docs/setup/04-ado-oidc.md](../../docs/setup/04-ado-oidc.md)

## Timing

SETUP_REQUIRED — populated in Phases 2–4.
