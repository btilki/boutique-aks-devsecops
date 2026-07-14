# Terraform

## Purpose

Azure infrastructure as code: remote state bootstrap, environment root for the single AKS platform, and reusable modules.

## Contents

- `bootstrap/` — one-time remote state storage (Phase 1)
- `environments/dev/` — platform root module: VNet, AKS, ACR, Key Vault, DNS (Phases 2–4)
- `modules/` — composable Terraform modules

## Prerequisites

- Azure CLI logged in with subscription access
- Terraform >= 1.6
- Phase 0 complete

## Usage

See [docs/setup/01-terraform-bootstrap.md](../docs/setup/01-terraform-bootstrap.md) and following topics.

## Locked values

| Variable | Value |
|----------|-------|
| `location` | `germanywestcentral` |
| `system_node_vm_size` | `Standard_D2s_v5` |
| `user_node_vm_size` | `Standard_D4s_v5` |

## Related documentation

- [ARCHITECTURE.md](../ARCHITECTURE.md)
- [docs/architecture/03-component-design.md](../docs/architecture/03-component-design.md)

## Timing

SETUP_REQUIRED — modules and env root populated Phases 1–4.
