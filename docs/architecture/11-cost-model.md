# Cost model

Estimates for **germanywestcentral**, lab usage, order-of-magnitude (EUR/month). Actual cost varies with uptime, egress, and Log Analytics ingestion.

## Core resources

| Resource | Est. monthly | Cost driver | Optimization |
|----------|--------------|-------------|--------------|
| AKS control plane | ~€65 | Per cluster | Single cluster only |
| System node `Standard_D2s_v5` × 1 | ~€60 | VM hours | Fixed count 1 |
| User node `Standard_D4s_v5` × 1–3 | ~€90–270 | Autoscale | min=1; stop when not labbing |
| Load Balancer (ingress) | ~€20 | Public LB | Single LB |
| ACR Basic | ~€5 | Storage | **Destroyed Phase 14** |
| Key Vault | ~€1 | Operations | Minimal secrets |
| Azure DNS zone | ~€0.50 | Hosted zone | Keep or delete post-teardown |
| Log Analytics | ~€5–30 | Ingestion GB | Filter noisy logs |

**Typical active lab:** ~€150–250/month with 2 nodes running.

## Guardrails

| Guardrail | Implementation |
|-----------|----------------|
| Max nodes | User pool `max_count: 3` |
| VM SKUs locked | D2s_v5 system, D4s_v5 user — no larger without ADR |
| Log retention | 30d LAW default; 15d Prometheus |
| Teardown | Phase 14 mandatory for cost stop |
| Destroy ACR | Removes storage + pull costs |

## Teardown savings

Phase 14 `scripts/operations/teardown.sh` removes:

- AKS cluster (largest cost)
- ACR (approved: destroy)
- Load balancers
- (Optional) Key Vault, DNS zone per runbook choice

Retain only Terraform bootstrap state storage if rebuilding quickly (~€1–2/month).

## Verification command

```bash
az consumption usage list --start-date $(date -u +%Y-%m-01) --end-date $(date -u +%Y-%m-%d) -o table
```

See `docs/setup/13-teardown.md` (Phase 14).
