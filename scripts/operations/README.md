# Operations scripts

Guarded helpers for day-2 operations. **Do not** bypass `docs/setup/` procedures.

| Script | Purpose |
|--------|---------|
| [teardown.sh](teardown.sh) | Destroy platform Azure resources (Topic 13) |

## teardown.sh

```bash
chmod +x scripts/operations/teardown.sh

# Preview destroy plan
./scripts/operations/teardown.sh --confirm destroy-boutique-platform --dry-run

# Destroy platform (AKS, ACR, KV, DNS, VNet, LAW)
./scripts/operations/teardown.sh --confirm destroy-boutique-platform

# Also remove Terraform remote state backend
./scripts/operations/teardown.sh --confirm destroy-boutique-platform --destroy-bootstrap
```

**Safety:** Requires exact confirmation phrase `destroy-boutique-platform`.

**Authority:** [docs/setup/13-teardown.md](../../docs/setup/13-teardown.md) · [docs/runbooks/teardown.md](../../docs/runbooks/teardown.md)
