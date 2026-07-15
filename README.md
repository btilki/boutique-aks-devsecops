# boutique-aks-devsecops

Production-pilot Azure DevSecOps reference platform for [Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo) **v0.10.5** on AKS.

Secure supply chain (Trivy + cosign + Kyverno), GitOps (Argo CD), Key Vault secrets, and digest-based promotion across **dev / stage / prod namespaces** on **one** cost-conscious cluster in `germanywestcentral`.

## Status

| Item | State |
|------|--------|
| Planning | Complete |
| Implementation | Setup Topics **00–13** complete; Azure lab **torn down** |
| Region | `germanywestcentral` (when rebuilt) |
| Node SKUs | System `Standard_D2s_v6`, User `Standard_D4s_v6` |

## Limitations

This is a **production pilot**, not enterprise production HA. Honesty here is part of the design.

**Do not call this production-ready.** Environments named `prod` are **logical namespaces on one cluster**, not a multi-cluster production estate.

| What this repo proves | What it does **not** claim |
|-----------------------|----------------------------|
| End-to-end DevSecOps on Azure AKS | Multi-region / multi-cluster failover |
| Signed digests + Kyverno admission | Separate clusters per environment |
| GitOps promotion with ADO prod approval | WAF, DDoS protection, HSM-backed keys |
| Metrics, lab SLO, Alertmanager UI | 24×7 on-call, Tempo/Jaeger, SOC SIEM |
| Rebuild-from-Git DR (hours) | Enterprise RTO/RPO or automatic DR |
| Boutique × up to 3 namespaces on one cluster | Unlimited scale; blast radius is the whole cluster |

**Cost:** ~€150–250/month when active. Teardown destroys ACR (re-mirror required). More detail: [ARCHITECTURE.md](ARCHITECTURE.md) · [docs/architecture/08-resilience-and-dr.md](docs/architecture/08-resilience-and-dr.md) · [docs/security/threat-model.md](docs/security/threat-model.md).

**Public-share hygiene (keep):** no empty `.github/workflows`, no “production-ready” wording, no marketing badge grids — see [CONTRIBUTING.md](CONTRIBUTING.md#public-share-hygiene).

## CI story

| Role | Platform | Notes |
|------|----------|-------|
| **Source of truth** | **GitHub** | Clone, PRs, Argo CD sync, digest commits |
| **CI / CD runs** | **Azure DevOps** | Mirror → Trivy → cosign → promote; OIDC to Azure |
| **GitHub Actions** | **Not used** | No `.github/workflows` — by design |

```text
GitHub (git)  ──checkout──►  Azure DevOps pipelines/
       ▲                              │
       │                         push digests
       └──────── Argo CD ◄────────────┘
                    │
                    ▼
                 AKS + ACR
```

YAML lives in [`pipelines/`](pipelines/). Auth is ADO **OIDC** (no long-lived pipeline secrets). Setup: [docs/setup/09-ci-pipeline.md](docs/setup/09-ci-pipeline.md). Index: [pipelines/README.md](pipelines/README.md). Local checks: `pre-commit` + [tests/README.md](tests/README.md).

## Quick links

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Executive architecture summary |
| [CHANGELOG.md](CHANGELOG.md) | Notable changes |
| [ROADMAP.md](ROADMAP.md) | Phase tracker and milestones |
| [docs/setup/README.md](docs/setup/README.md) | Authoritative setup guide index |
| [docs/operations/README.md](docs/operations/README.md) | Day-2 runbooks |
| [docs/architecture/README.md](docs/architecture/README.md) | Deep architecture docs |
| [versions.yaml](versions.yaml) | Pinned tool, chart, and app versions |

## Hostnames

**Lab offline.** These FQDNs were used for the lived pilot; they resolve only after you rebuild Topics 02–12. For storefront / UI proof, see [Visual evidence](#visual-evidence).

| Service | FQDN (when lab is live) |
|---------|-------------------------|
| Argo CD | `argocd-boutique.biroltilki.art` |
| Grafana | `grafana-boutique.biroltilki.art` |
| Boutique dev | `dev-boutique.biroltilki.art` |
| Boutique stage | `stage-boutique.biroltilki.art` |
| Boutique prod | `boutique.biroltilki.art` |

## Visual evidence

Setup screenshots live under [`assets/images/setup/`](assets/images/setup/) and are linked from matching [`docs/setup/`](docs/setup/) topics. Catalog: [`assets/images/README.md`](assets/images/README.md). Use these when public URLs are offline.

## Repository layout

```text
terraform/    # Azure IaC (bootstrap, modules, environments/dev)
gitops/       # Argo CD bootstrap, platform services, Boutique overlays
policies/     # Kyverno cluster policies and tests
pipelines/    # Azure DevOps CI (not GitHub Actions)
docs/         # Architecture, setup, security, runbooks
scripts/      # Guarded operational helpers (teardown, OIDC verify)
tests/        # Terraform, policy, integration validation
examples/     # Runnable demos (CSI secret test)
```

## Getting started

1. **New lab:** start at [docs/setup/00-prerequisites.md](docs/setup/00-prerequisites.md), then follow [docs/setup/](docs/setup/) in order.
2. **Existing lab:** run P0 checks in [tests/README.md](tests/README.md); do not re-apply foundation blindly.
3. Confirm each topic before the next; authoritative steps live only under `docs/setup/`.

## Security

Do not commit secrets, keys, or `terraform.tfvars` with real values. See [SECURITY.md](SECURITY.md).

## License

Apache License 2.0 — see [LICENSE](LICENSE).
