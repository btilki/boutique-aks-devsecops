# Rollback

**Audience:** L3 — Operator
**Applies to:** stage / prod (dev via Git revert + auto-sync)
**Prerequisites:** Git history for overlay; Argo app access
**Estimated time:** 15–30 minutes
**Risk level:** Medium

## Purpose

Return an environment to the last known-good digest pins after a bad promote.

## When to use / When not to use

**Use** when smoke fails, error budget burn, or Kyverno/runtime failure after sync.
**Do not use** Argo “History Rollback” without fixing Git afterward (creates drift). Preferred: **Git revert**.

## Prerequisites

- [ ] Note current image: `kubectl get deploy -n boutique-<env> frontend -o jsonpath='{.spec.template.spec.containers[0].image}'`
- [ ] Identify bad commit on the overlay `kustomization.yaml`

## Procedure

### Step 1: Revert the promotion commit

**Commands:**

```bash
git log -5 --oneline -- gitops/apps/boutique/overlays/<env>/kustomization.yaml
git revert <bad-commit-sha> --no-edit
git push origin main
```

**Validation:** Reverted file shows prior digests; `git status` clean after push.

**Expected outcome:** Good digests restored in Git.

**Recovery steps:** If revert conflicts, manually restore `images:` block from last good commit.

**Best practices:** Prefer `git revert` over `reset --hard` on `main`.

### Step 2: Sync Argo

**Commands:**

```bash
kubectl patch application boutique-<env> -n argocd --type merge -p \
  '{"operation":{"initiatedBy":{"username":"ops"},"sync":{"revision":"main","prune":true}}}'
kubectl rollout status deploy/frontend -n boutique-<env> --timeout=180s
```

**Validation:** Application Synced/Healthy; pods Running.

### Step 3: Rollback smoke

**Commands:**

```bash
./tests/integration/rollback-smoke.sh <env>
```

**Validation:** Exit 0.

## End-to-end validation

Deep procedure: [promotion-rollback.md](../runbooks/promotion-rollback.md).

## Rollback (section-level)

If revert was wrong, revert the revert commit and re-sync (document why).

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| `BoutiqueFrontendDown` | Boutique Overview | — |

## Security notes

Do not disable Kyverno to “force” a bad image through.

## Automation opportunities

Document last-known-good digests in release notes (Release Prompt).
