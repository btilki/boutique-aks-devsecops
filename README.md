# boutique-aks-devsecops

Production-pilot Azure DevSecOps reference platform for [Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo) **v0.10.5** on AKS.

Secure supply chain (Trivy + cosign + Kyverno), GitOps delivery (Argo CD), Key Vault secrets, digest-based promotion across dev/stage/prod namespaces on **one** cost-conscious cluster.

**Version control:** [GitHub](https://github.com) — Azure DevOps is used for CI/CD and OIDC only.

## Status

| Item | State |
|------|--------|
| Planning | Complete |
| Implementation | Phase 0 — architecture & structure scaffold complete |
| Region | `germanywestcentral` |
| Node SKUs | System `Standard_D2s_v5`, User `Standard_D4s_v5` |

## Quick links

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Executive architecture summary |
| [ROADMAP.md](ROADMAP.md) | Phase tracker and milestones |
| [docs/implementation/plan.md](docs/implementation/plan.md) | Detailed implementation plan |
| [docs/setup/README.md](docs/setup/README.md) | Authoritative setup guide index |
| [docs/architecture/README.md](docs/architecture/README.md) | Deep architecture docs |
| [versions.yaml](versions.yaml) | Pinned tool, chart, and app versions |

## Hostnames

| Service | FQDN |
|---------|------|
| Argo CD | `argocd-boutique.biroltilki.art` |
| Grafana | `grafana-boutique.biroltilki.art` |
| Boutique dev | `dev-boutique.biroltilki.art` |
| Boutique stage | `stage-boutique.biroltilki.art` |
| Boutique prod | `boutique.biroltilki.art` |

## Repository layout

```text
terraform/    # Azure IaC (bootstrap, modules, environments/dev)
gitops/       # Argo CD bootstrap, platform services, Boutique overlays
policies/     # Kyverno cluster policies and tests
pipelines/    # Azure DevOps mirror, scan, sign, promote
docs/         # Architecture, setup, security, runbooks
scripts/      # Guarded operational helpers (teardown, OIDC verify)
tests/        # Terraform, policy, integration validation
examples/     # Runnable demos (CSI secret test)
```

## Getting started

1. Read [docs/setup/00-prerequisites.md](docs/setup/00-prerequisites.md) — install tools, connect GitHub, run pre-commit.
2. Follow numbered setup topics in order — do not skip validation steps.
3. Implement **one phase per PR**; confirm each phase before continuing.

## Security

Do not commit secrets, keys, or `terraform.tfvars` with real values. See [SECURITY.md](SECURITY.md).

## License

Apache License 2.0 — see [LICENSE](LICENSE).
