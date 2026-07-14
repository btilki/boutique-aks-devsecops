# Promotion and rollback runbook

Operational procedure for moving **the same signed digest** from dev → stage → prod on the single AKS cluster.

**Related:** [12-promotion-stage-prod.md](../setup/12-promotion-stage-prod.md), [ADR-0008](../adr/0008-ado-prod-approval-gate.md)

---

## Promotion model

| Step | Environment | Git change | Argo CD sync | Human gate |
|------|-------------|------------|--------------|------------|
| 1 | dev | Auto or pipeline | **Automatic** | Dev smoke test |
| 2 | stage | Copy/promote digests | **Manual** | Stage smoke + Grafana |
| 3 | prod | Same digest as stage | **Manual** | **ADO environment approval** + prod smoke |

**Rule:** Never promote a digest to prod that was not validated in stage.

---

## Preconditions

- [ ] Dev smoke test passes: `./tests/integration/dev-smoke.sh`
- [ ] Grafana Boutique dashboard shows healthy frontend replicas
- [ ] SLO error budget not exhausted ([boutique-availability.md](../slo/boutique-availability.md))
- [ ] Kyverno policies enforcing signatures

---

## Promote to stage

### Option A — Manual Git (recommended for first promotion)

1. Copy `images:` block (digest pins) from `gitops/apps/boutique/overlays/dev/kustomization.yaml` to `overlays/stage/kustomization.yaml`.
2. Commit and push to `main`.
3. Argo CD → **boutique-stage** → **Sync** (not auto).
4. Create DNS A record `stage-boutique` → ingress IP if missing.
5. Run `./tests/integration/promotion-smoke.sh stage`.

### Option B — ADO pipeline

1. Queue `pipelines/azure-pipelines-promote.yml` with stage parameter path (runs MirrorScanSign → Promote_stage).
2. After pipeline green, manual Argo sync **boutique-stage**.
3. Run promotion smoke test.

---

## Promote to prod

1. Confirm stage smoke passed for **at least 24h** (lab minimum: same session after stage validation).
2. Copy validated `images:` block from stage overlay to `overlays/prod/kustomization.yaml`.
3. **ADO:** Queue promotion pipeline prod stage **or** push Git commit — **prod** environment approval required before job runs (if using pipeline).
4. Argo CD → **boutique-prod** → **Sync** (manual).
5. DNS: `boutique.biroltilki.art` → ingress IP.
6. Run `./tests/integration/promotion-smoke.sh prod`.

---

## Rollback

### Application rollback (preferred)

1. Identify last known-good commit for overlay `kustomization.yaml` (digest pins).
2. `git revert <bad-commit>` or restore prior `images:` block.
3. Push to `main`.
4. Argo CD → **Sync** affected app (`boutique-stage` or `boutique-prod`).
5. `./tests/integration/rollback-smoke.sh <env>`

### Argo CD history rollback

1. Argo CD → Application → **History and rollback** → select previous revision.
2. **Rollback** (creates drift from Git — reconcile Git afterward).

### Emergency scale-out

If single pod failure:

```bash
kubectl rollout restart deployment/frontend -n boutique-<env>
kubectl rollout status deployment/frontend -n boutique-<env>
```

Does not fix bad digest — use Git revert for image issues.

---

## Verification checklist

| Check | Command |
|-------|---------|
| Same digest dev/stage/prod | `grep -A2 'name:.*frontend' gitops/apps/boutique/overlays/*/kustomization.yaml` |
| Argo sync status | `kubectl get application -n argocd boutique-stage boutique-prod` |
| Ingress TLS | `kubectl get certificate -n boutique-stage -n boutique-prod` |
| Health | `./tests/integration/promotion-smoke.sh all` |

---

## When to stop promotion

- Dev or stage smoke test fails
- `BoutiqueFrontendDown` alert firing
- New digest fails Kyverno admission (unsigned image)
- Operator rejects ADO prod approval

Document incident in change log; do not sync prod.

---

## References

- [promotion-failures.md](../troubleshooting/promotion-failures.md)
- [argocd-sync.md](../troubleshooting/argocd-sync.md)
- [image-signature.md](../troubleshooting/image-signature.md)
