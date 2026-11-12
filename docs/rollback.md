# Rollback — restore previous digests from Git

Audience: Implementer or operator · Topic 12 · Related: [promotion.md](promotion.md), [operations/03-rollback.md](operations/03-rollback.md)

## Principle

Desired state lives in Git. Rollback means putting the previous digests back with `git revert`, or with a new commit that restores known-good digests. Argo CD then reconciles. Do **not** rely on `kubectl set image` or Argo History Rollback alone — that drifts away from Git.

## When to rollback

| Signal | Action |
|--------|--------|
| Stage unhealthy after promote | Revert the stage digest commit; fix forward in dev |
| Prod unhealthy after manual sync | Revert the prod digest commit; sync Argo again by hand |
| Smoke or Kyverno failure after sync | Prefer a Git revert over a cluster-only undo |

## At a glance

```bash
git log -5 --oneline -- gitops/apps/boutique/overlays/<env>/kustomization.yaml
git revert <bad-commit-sha> --no-edit
git push origin main
# Then: Argo sync for boutique-stage / boutique-prod (manual)
```

Full operator procedure: [operations/03-rollback.md](operations/03-rollback.md) · [runbooks/promotion-rollback.md](runbooks/promotion-rollback.md).

## What not to do

| Anti-pattern | Why |
|--------------|-----|
| `kubectl rollout undo` only | The next Argo sync puts the bad digest back |
| Delete pods hoping for an old image | Git still points at the bad digest |
| Force-push rewrite of `main` | Breaks the audit trail |
| Hot-patch prod digests outside Git | Breaks the CI and GitOps contract |

## Validation

After Argo reconciles:

- Pods in `boutique-<env>` show the restored digests
- Storefront HTTPS responds for that environment when the cluster is live
- The Argo Application for that environment is Synced and Healthy

## Where to go next

| Need | Open |
|------|------|
| Day-2 rollback runbook | [operations/03-rollback.md](operations/03-rollback.md) |
| Promotion contract | [promotion.md](promotion.md) |
| Common incident patterns | [operations/17-common-incidents.md](operations/17-common-incidents.md) |
