# Module: aks

## Purpose

AKS cluster with system (D2s_v6) and user (D4s_v6) node pools in germanywestcentral.

**Autoscaling note:** The user pool sets `enable_auto_scaling = true` and uses `lifecycle.ignore_changes` on `node_count` (and `upgrade_settings`) so Terraform does not fight the cluster autoscaler. The cluster resource ignores `microsoft_defender` drift when Defender for Containers is enabled outside this module.

## Inputs

Documented in `variables.tf` (Phase 2–4). See `terraform.tfvars.example` in environment root.

## Outputs

Documented in `outputs.tf`. Consumed by environment root, GitOps docs, or ADO setup.

## Dependencies

See [docs/implementation/plan.md](../../../docs/implementation/plan.md) for phase ordering.

## Usage

```hcl
module "aks" {
  source = "../../modules/aks"
  # ...
}
```

See matching [docs/setup/](../../../docs/setup/) topic.

## Timing

SETUP_REQUIRED — populated in Phases 2–4.
