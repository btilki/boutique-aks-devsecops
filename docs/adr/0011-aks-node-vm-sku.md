# ADR-0011: AKS node VM SKUs and region

## Status

Accepted (amended 2026-07-15 — Dsv6 test fallback)

## Context

Platform runs in EU Central. VM SKUs must be available in the target region for this subscription. Verified via `az vm list-skus` (2026-07-14).

During Topic 03 apply, subscription **Standard DSv5 Family vCPU quota** in `germanywestcentral` was **0** (`ErrCode_InsufficientVCPUQuota`), while **Standard Dsv6 Family** quota was **10**. SKUs remain available in-region for both families.

## Decision

| Setting | Value |
|---------|-------|
| Region | `germanywestcentral` |
| System pool | `Standard_D2s_v6` (1 node, fixed) — **test default when DSv5 quota is 0** |
| User pool | `Standard_D4s_v6` (1–3 nodes, autoscaler) — **test default when DSv5 quota is 0** |
| Preferred (when quota allows) | `Standard_D2s_v5` / `Standard_D4s_v5` per original pilot design |

## Consequences

- **Positive:** Dsv6 available with quota in this subscription; equivalent core/memory class to Dsv5 for test workloads.
- **Negative:** Diverges from original Dsv5 cost estimates until DSv5 quota is increased.
- **Operational:** Request DSv5 quota increase via Azure Portal if reverting to original SKUs later.

## Validation

```bash
az vm list-usage --location germanywestcentral \
  --query "[?contains(name.value,'Dsv6') || contains(name.value,'DSv5')].{family:name.localizedValue, used:currentValue, limit:limit}" \
  -o table

az vm list-skus --location germanywestcentral --size Standard_D4s_v6 --all -o table
```
