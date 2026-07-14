# GitOps

## Purpose

Declarative Kubernetes state managed by Argo CD: platform services and Online Boutique overlays. All manifests sync from **GitHub** (`https://github.com/<GITHUB_ORG>/<REPO_NAME>`).

## Contents

| Path | Purpose |
|------|---------|
| `bootstrap/` | Argo CD install, root app-of-apps |
| `projects/` | Argo CD AppProjects |
| `platform/` | Ingress, cert-manager, Kyverno, CSI, monitoring |
| `apps/boutique/` | Kustomize base + dev/stage/prod overlays |

## Prerequisites

- AKS cluster reachable
- Argo CD installed (Phase 5)
- GitHub repository pushed (Topic 00 Step 4); `repoURL` placeholders patched (Topic 05 Step 5.6)

## Usage

[docs/setup/05-gitops-bootstrap.md](../docs/setup/05-gitops-bootstrap.md)

## Related documentation

- [docs/architecture/05-deployment-flow.md](../docs/architecture/05-deployment-flow.md)

## Timing

SETUP_REQUIRED (`bootstrap/`, `projects/`) Phase 5; platform/apps per later phases.
