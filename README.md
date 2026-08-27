# boutique-aks-devsecops

Production-pilot Azure DevSecOps reference platform for [Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo) **v0.10.5** on AKS.

Secure supply chain (Trivy + cosign + Kyverno), GitOps (Argo CD), Key Vault secrets, and digest-based promotion across **dev / stage / prod namespaces** on **one** cost-conscious cluster in `germanywestcentral`.

Part of the [DevOps Engineering Playbook](https://github.com/btilki/devops-engineering-playbook) · Author: [Birol Tilki](https://www.linkedin.com/in/birol-tilki-48731326/)

### At a glance (30 seconds)

| | |
|-|-|
| **What** | DevSecOps on Azure AKS — signed digests, Kyverno admission, GitOps promotion |
| **CI model** | **GitHub** = source of truth · **Azure DevOps** = pipelines (OIDC) · no GitHub Actions |
| **Hard rule** | Unsigned / floating tags should not reach the cluster |
| **Proven** | Setup Topics 00–13 lived and **torn down**; Topics 14–20 scaffold-only until rebuild |
| **Start reading** | [CI story](#ci-story) → [ARCHITECTURE.md](ARCHITECTURE.md) → [docs/security/threat-model.md](docs/security/threat-model.md) |
| **Playbook brief** | [featured project](https://github.com/btilki/devops-engineering-playbook/blob/main/featured-projects/boutique-aks-devsecops.md) |

## Status

| Item | State |
|------|--------|
| Planning | Phase 15+ **scaffold complete** — [phase15-plus.md](docs/implementation/phase15-plus.md) |
| Implementation | Setup Topics **00–13** complete; Azure test **torn down**; Topics **14–20** scaffolded (apply after rebuild) |
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
| Metrics, test SLO, Alertmanager UI | 24×7 on-call, Tempo/Jaeger, SOC SIEM |
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
| [docs/implementation/phase15-plus.md](docs/implementation/phase15-plus.md) | Phase 15+ fuller DevSecOps packages (scaffold-first) |
| [docs/setup/README.md](docs/setup/README.md) | Authoritative setup guide index |
| [docs/operations/README.md](docs/operations/README.md) | Day-2 runbooks |
| [docs/architecture/README.md](docs/architecture/README.md) | Deep architecture docs |
| [versions.yaml](versions.yaml) | Pinned tool, chart, and app versions |

## Hostnames

**Test offline.** These FQDNs were used for the lived pilot; they resolve only after you rebuild Topics 02–12. For storefront / UI proof, see [Visual evidence](#visual-evidence).

| Service | FQDN (when test is live) |
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

1. **New test (Topics 00–13):** start at [docs/setup/00-prerequisites.md](docs/setup/00-prerequisites.md), then follow Topics **00–12** (and **13** when tearing down).
2. **Rebuild after teardown:** same path; do not re-apply foundation blindly — see [tests/README.md](tests/README.md) P0 checks.
3. **Phase 15+ (Topics 14–20):** scaffold is in Git; apply only after Topics 00–12 are live again — [phase15-plus.md](docs/implementation/phase15-plus.md).
4. Confirm each topic before the next; authoritative steps live only under `docs/setup/`.

## Security

Do not commit secrets, keys, or `terraform.tfvars` with real values. See [SECURITY.md](SECURITY.md).

## Related portfolio

| Resource | Link |
|----------|------|
| **DevOps Engineering Playbook** (hub) | https://github.com/btilki/devops-engineering-playbook |
| Playbook project brief | https://github.com/btilki/devops-engineering-playbook/blob/main/featured-projects/boutique-aks-devsecops.md |
| Article A1 — GitHub + Azure DevOps on AKS | https://github.com/btilki/devops-engineering-playbook/blob/main/articles/A1.md |
| Article A2 — Kyverno + Cosign unsigned deny | https://github.com/btilki/devops-engineering-playbook/blob/main/articles/A2.md |
| Article A3 — Destroy ACR on teardown | https://github.com/btilki/devops-engineering-playbook/blob/main/articles/A3.md |
| Article X1 — Online Boutique on EKS, GKE, and AKS | https://github.com/btilki/devops-engineering-playbook/blob/main/articles/X1.md |
| Article X2 — Single cluster vs multi-cluster | https://github.com/btilki/devops-engineering-playbook/blob/main/articles/X2.md |
| Sister platform — EKS GitOps | https://github.com/btilki/boutique-eks-gitops |
| Sister platform — GKE SRE | https://github.com/btilki/boutique-gke-sre |
| *Practical DevSecOps on Azure Kubernetes Service* (Boutique Production) | https://github.com/btilki/learn-devops-by-building/tree/main/boutique-production/aks-devsecops |
| LinkedIn | https://www.linkedin.com/in/birol-tilki-48731326/ |

## License

Apache License 2.0 — see [LICENSE](LICENSE).
