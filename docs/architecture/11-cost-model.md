# Cost model

Estimates for **germanywestcentral**, test usage, order-of-magnitude (EUR/month). Actual cost varies with uptime and egress.

## Core resources

| Resource | Est. monthly | Cost driver | Optimization |
|----------|--------------|-------------|--------------|
| AKS control plane | ~€65 | Per cluster | Single cluster only |
| System node `Standard_D2s_v6` × 1 | ~€60 | VM hours | Fixed count 1 |
| User node `Standard_D4s_v6` × 1–3 | ~€90–270 | Autoscale | min=1; stop when not labbing |
| Load Balancer (ingress) | ~€20 | Public LB | Single LB |
| ACR Basic | ~€5 | Storage | **Destroyed Phase 14** |
| Key Vault | ~€1 | Operations | Minimal secrets |
| Azure DNS zone | ~€0.50 | Hosted zone | Keep or delete post-teardown |
| Loki (in-cluster) | ~€0 Azure | PVC on node disk | 10Gi test default; no Log Analytics |

**Typical active test:** ~€150–220/month with 2 nodes running (Log Analytics removed per ADR-0012).

## Guardrails

| Guardrail | Implementation |
|-----------|----------------|
| Max nodes | User pool `max_count: 3` |
| VM SKUs locked | D2s_v6 system, D4s_v6 user — no larger without ADR |
| Log retention | Loki PVC 10Gi; Prometheus 15d |
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
