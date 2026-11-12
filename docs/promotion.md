# Promotion — digest pins across namespaces

Audience: Implementer or release owner · Topic 12 · ADR [0008](adr/0008-ado-prod-approval-gate.md) · Related: [rollback.md](rollback.md), [ci.md](ci.md)

## Goal

Move the same signed image digests from `boutique-dev` to `boutique-stage` to `boutique-prod` by updating GitOps overlays. Argo CD reconciles from Git. The pipeline does not call `kubectl` or `argocd sync`.

## At a glance

| Env | Namespace | Overlay | Argo sync | Gate |
|-----|-----------|---------|-----------|------|
| dev | `boutique-dev` | `gitops/apps/boutique/overlays/dev/` | Automatic | — |
| stage | `boutique-stage` | `gitops/apps/boutique/overlays/stage/` | Manual | — |
| prod | `boutique-prod` | `gitops/apps/boutique/overlays/prod/` | Manual | **ADO environment approval** |

Hostnames when rebuilt: `dev-boutique.biroltilki.art`, `stage-boutique.biroltilki.art`, `boutique.biroltilki.art`.

## Hard rules

| Rule | Detail |
|------|--------|
| Same digest | Promote the digest that already passed earlier environments — do not retag |
| Digest-only overlay edits | Promotion commits change image digests in `kustomization.yaml`, not application code |
| Stage before prod | Do not skip stage on the happy path |
| Prod approval | ADO environment approval before the prod promote job (ADR-0008) |
| Manual Argo for stage/prod | After Git updates, sync stage and prod in Argo CD |

## How promotion runs

1. The supply-chain pipeline writes `digest-manifest.json` (Topic 09).
2. The promote template updates the target overlay and pushes to GitHub ([`pipelines/templates/promote-digest.yml`](../pipelines/templates/promote-digest.yml)).
3. Argo CD syncs — automatic for dev, manual for stage and prod.

Full procedure: [setup/12-promotion-stage-prod.md](setup/12-promotion-stage-prod.md).

## Reviewer checklist

- [ ] Diff is digest pins only (unless an overlay change is called out)
- [ ] Digests match what was tested in the previous environment
- [ ] Stage was promoted before prod
- [ ] Prod waited for ADO approval
- [ ] Stage and prod Argo apps are Healthy after manual sync

## Where to go next

| Need | Open |
|------|------|
| Step-by-step setup | [setup/12-promotion-stage-prod.md](setup/12-promotion-stage-prod.md) |
| Deployment flow diagram | [architecture/05-deployment-flow.md](architecture/05-deployment-flow.md) |
| If a promote goes wrong | [rollback.md](rollback.md) |
