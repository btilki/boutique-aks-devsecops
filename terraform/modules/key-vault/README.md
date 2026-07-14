# Module: key-vault

## Purpose

Key Vault for platform and signing secrets.

## Inputs

Documented in `variables.tf` (Phase 2–4). See `terraform.tfvars.example` in environment root.

## Outputs

Documented in `outputs.tf`. Consumed by environment root, GitOps docs, or ADO setup.

## Dependencies

See [docs/implementation/plan.md](../../../docs/implementation/plan.md) for phase ordering.

## Usage

```hcl
module "key-vault" {
  source = "../../modules/key-vault"
  # ...
}
```

See matching [docs/setup/](../../../docs/setup/) topic.

## Timing

SETUP_REQUIRED — populated in Phases 2–4.
