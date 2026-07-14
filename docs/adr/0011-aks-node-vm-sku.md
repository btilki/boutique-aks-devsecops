# ADR-0011: AKS node VM SKUs and region

## Status

Accepted

## Context

Platform runs in EU Central. VM SKUs must be available in the target region for this subscription. Verified via `az vm list-skus` (2026-07-14).

## Decision

| Setting | Value |
|---------|-------|
| Region | `germanywestcentral` |
| System pool | `Standard_D2s_v5` (1 node, fixed) |
| User pool | `Standard_D4s_v5` (1–3 nodes, autoscaler) |

## Consequences

- **Positive:** Dsv5 available with no subscription restrictions in `germanywestcentral`; sufficient CPU for Boutique × 3 envs.
- **Negative:** `westeurope`/`northeurope` Dsv5 blocked for this subscription — do not deploy there without re-validation.

## Validation

```bash
az vm list-skus --location germanywestcentral --size Standard_D4s_v5 --all -o table
```
