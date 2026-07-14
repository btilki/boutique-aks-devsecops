# Teardown runbook

Destroy billable Azure platform resources when the lab is complete or paused long-term.

**Related:** [13-teardown.md](../setup/13-teardown.md), [ADR-0010](../adr/0010-destroy-acr-on-teardown.md), [11-cost-model.md](../architecture/11-cost-model.md)

---

## What gets destroyed

| Resource | Method | Notes |
|----------|--------|-------|
| AKS cluster | `terraform destroy` (dev) | Largest cost item |
| ACR (+ all mirrored images) | Same | **Destroyed** per ADR-0010 |
| Key Vault | Same | Soft-delete 7 days; purge for name reuse |
| Azure DNS zone `biroltilki.art` | Same | Update registrar NS if zone removed |
| VNet, NSG, LAW | Same | Platform RG removed |
| Load balancers | Removed with AKS/ingress | Public IPs released |

## Retained by default

| Resource | Why |
|----------|-----|
| Bootstrap storage (TF state) | Faster rebuild (~€1–2/mo) |
| Git repository / ADO project | Source of truth |
| Domain at registrar | You own `biroltilki.art` |

---

## Pre-teardown checklist

- [ ] Export cosign **public** key from repo/KV if not already in Git (`policies/kyverno/...`)
- [ ] Optional: `kubectl config` backup
- [ ] Disable or pause ADO pipelines (avoid failed runs against dead cluster)
- [ ] Confirm no production dependency on this lab cluster
- [ ] Run dry-run: `./scripts/operations/teardown.sh --confirm destroy-boutique-platform --dry-run`

---

## Teardown procedure

### 1. Optional — scale down GitOps (cluster still up)

```bash
argocd app delete boutique-prod boutique-stage boutique-dev --cascade 2>/dev/null || true
argocd app delete platform-root apps-root --cascade 2>/dev/null || true
```

Skip if cluster already unreachable — Terraform destroy removes the cluster.

### 2. Destroy platform (Terraform)

```bash
cd /path/to/boutique-aks-devsecops
./scripts/operations/teardown.sh --confirm destroy-boutique-platform
```

Manual equivalent:

```bash
cd terraform/environments/dev
terraform init
terraform destroy
```

### 3. Verify Azure cleanup

```bash
az group list --query "[?contains(name, 'boutique')]" -o table
az aks list -o table
az acr list -o table
az network dns zone list -o table
```

Expect **no** platform RG, AKS, or ACR from this project.

### 4. Key Vault soft-delete purge (if reusing name)

```bash
az keyvault list-deleted -o table
az keyvault purge --name kv-boutique-dev-gwc   # your KV name
```

### 5. DNS registrar

If Azure DNS zone was destroyed, remove NS delegation to Azure nameservers at your registrar (or point elsewhere).

### 6. Optional — destroy bootstrap state

Only when fully decommissioning the project:

```bash
./scripts/operations/teardown.sh --confirm destroy-boutique-platform --destroy-bootstrap
```

---

## Post-teardown

| Task | Action |
|------|--------|
| Rebuild platform | Topics 01–12 from setup guide |
| Restore images | Re-run Topic 09 mirror pipeline (ACR was destroyed) |
| Cost check | `az consumption usage list` after 24–48h |

---

## Partial teardown / stuck destroy

| Symptom | Fix |
|---------|-----|
| RG delete blocked | Empty nested resources; `az resource list -g <rg>` |
| AKS delete timeout | Wait 15–30 min; retry `terraform destroy` |
| KV name reserved | `az keyvault purge` |
| Terraform state lock | Break lease on state blob in bootstrap storage |
| Bootstrap destroy fails | Dev state still in container — destroy dev first |

---

## Emergency stop (cost without full teardown)

Scale user node pool to 0 (temporary):

```bash
az aks nodepool scale --cluster-name <aks> --resource-group <rg> \
  --name user --node-count 0
```

Not a substitute for Phase 14 teardown — control plane charges continue.

---

## References

- [incident-response.md](incident-response.md) — if teardown triggered by incident
- [01-terraform-bootstrap.md](../setup/01-terraform-bootstrap.md) — bootstrap recreation
