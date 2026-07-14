# Module: diagnostics

## Purpose

Log Analytics workspace and diagnostic settings.

## Inputs

Documented in `variables.tf` (Phase 2–4). See `terraform.tfvars.example` in environment root.

## Outputs

Documented in `outputs.tf`. Consumed by environment root, GitOps docs, or ADO setup.

## Dependencies

See [docs/implementation/plan.md](../../../docs/implementation/plan.md) for phase ordering.

## Usage

```hcl
module "diagnostics" {
  source = "../../modules/diagnostics"
  # ...
}
```

See matching [docs/setup/](../../../docs/setup/) topic.

## Timing

SETUP_REQUIRED — populated in Phases 2–4.
