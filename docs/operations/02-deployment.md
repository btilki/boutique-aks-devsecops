# Deployment

**Audience:** L3 — Operator
**Applies to:** stage / prod (dev usually auto-synced)
**Prerequisites:** Signed digests in ACR; [promotion-rollback.md](../runbooks/promotion-rollback.md)
**Estimated time:** 20–40 minutes
**Risk level:** Medium

## Purpose

Promote the **same signed image digests** via GitOps into stage or prod and prove health with smoke tests.

## When to use / When not to use

**Use** after a green ADO mirror/scan/sign run and stage validation before prod.
**Do not use** to redeploy from Setup Topic 00–05 (wrong layer).

## Prerequisites

- [ ] Stage healthy before prod (`./tests/integration/promotion-smoke.sh stage`)
- [ ] Digest pins known (pipeline `digest-manifest` or existing stage overlay)
- [ ] Capacity: slim optional services if needed

## Procedure

### Step 1: Update overlay digests in Git

**Commands:**

```bash
# Edit gitops/apps/boutique/overlays/stage/kustomization.yaml  (or prod)
# images: blocks must match signed ACR digests

git add gitops/apps/boutique/overlays/<env>/
git commit -m "promote(<env>): digest pins YYYY-MM-DD"
git push origin main
```

**Validation:** `git show --stat` shows only intended overlay files.

**Expected outcome:** Push succeeds; ADO may rerun supply-chain if paths match.

**Recovery steps:** `git revert HEAD` if wrong digests committed.

**Best practices:** Copy digests from **stage** to **prod** — never promote untested digests to prod.

### Step 2: Manual Argo CD sync

**Commands:**

```bash
# Prefer UI: Argo CD → boutique-stage|boutique-prod → Sync (prune as needed)
# Or:
kubectl patch application boutique-<env> -n argocd --type merge -p \
  '{"operation":{"initiatedBy":{"username":"ops"},"sync":{"revision":"main","prune":true}}}'
kubectl get application -n argocd boutique-<env>
```

**GUI steps:**

1. Open `https://argocd-boutique.biroltilki.art`
2. Select **boutique-stage** or **boutique-prod**
3. **Sync** → enable prune if removing scaled/resources · Sync

**Validation:** Sync Status **Synced**, Health **Healthy** (or Progressing then Healthy).

**Expected outcome:** Deployments show digest images; frontend Ready.

**Recovery steps:** See [03-rollback.md](03-rollback.md).

### Step 3: Smoke test

**Commands:**

```bash
./tests/integration/promotion-smoke.sh stage   # or prod
```

**Validation:** Script exits 0; `/_healthz` HTTP 200.

## End-to-end validation

```bash
diff <(grep 'sha256:' gitops/apps/boutique/overlays/stage/kustomization.yaml) \
     <(grep 'sha256:' gitops/apps/boutique/overlays/prod/kustomization.yaml)
kubectl get deploy -n boutique-prod frontend -o jsonpath='{.spec.replicas}{"\n"}'
```

Prod frontend target replicas: **2** (replicas-patch).

## Rollback (section-level)

Follow [03-rollback.md](03-rollback.md) immediately if smoke fails.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| `BoutiqueFrontendDown` | Boutique Overview | `{namespace="boutique-stage"}` |

## Security notes

Prod Git digest updates that use the promote pipeline must pass **ADO environment approval**. Manual Git still requires operator discipline.

## Automation opportunities

Wire `pipelines/azure-pipelines-promote.yml` for routine promotes; keep manual Git for emergency.
