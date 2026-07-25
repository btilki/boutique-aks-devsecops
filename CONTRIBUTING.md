# Contributing

## Workflow

1. **One phase per PR** — see [ROADMAP.md](ROADMAP.md) and [docs/implementation/plan.md](docs/implementation/plan.md).
2. Follow the **Setup Guide** as the source of truth for implementation order.
3. Run `pre-commit run --all-files` before opening a PR.
4. Wait for phase validation before starting the next phase.

## CI

| | |
|--|--|
| **CI** | **Azure DevOps** (`pipelines/`) |
| **Git** | **GitHub** (source of truth for Argo CD and digest commits) |
| **GitHub Actions** | **Not used** — do not add empty `.github/workflows` |

Local: `pre-commit run --all-files`. Details: [README.md](README.md#ci-story) · [pipelines/README.md](pipelines/README.md).

## Public-share hygiene

Before merging README or top-level marketing copy:

| Avoid | Why / Do instead |
|-------|------------------|
| Empty `.github/workflows` (even “with README later”) | CI is ADO only — never create this tree |
| Claiming **production-ready** / enterprise-ready | Say **production pilot**; link [Limitations](README.md#limitations) |
| Shields.io / badge grids on README | Status tables and prose only — no badge walls |

## Documentation

- Every major directory has a `README.md` explaining purpose and usage.
- Terraform modules document: Purpose, Inputs, Outputs, Dependencies, Usage.
- Setup changes must update the matching `docs/setup/NN-topic.md`.

### Abbreviations (first mention)

In the **document that most closely relates** to a term, the **first** mention uses this format:

```text
**ABBR** (**Full Form**)
```

Example: **AKS** (**Azure Kubernetes Service**)

| Rule | Detail |
|------|--------|
| Order | Abbreviation first, full form in parentheses |
| Emphasis | Both the abbreviation and the full form are **bold** |
| Where | Only in the owning/home document for that term (not every file) |
| Later mentions | Abbreviation alone is enough (`AKS`, `SBOM`) |
| Titles | Prefer expanding in the first body paragraph (Topic goal / Purpose), not necessarily in the H1 |

**Home documents (Wave 2 examples):**

| Term | Expand in |
|------|-----------|
| **PRs** (pull request gates) | [14-pr-ci.md](docs/setup/14-pr-ci.md) |
| **AKS** / **ACR** / **WI** | [03-cluster-resources.md](docs/setup/03-cluster-resources.md) |
| **ADO** / **OIDC** / **PAT** | [04-ado-oidc.md](docs/setup/04-ado-oidc.md) |
| **CI** (supply-chain) | [09-ci-pipeline.md](docs/setup/09-ci-pipeline.md) |
| Network Policy / Azure **NPM** / **CNI** | [15-network-policies.md](docs/setup/15-network-policies.md) |
| **IaC** | [16-iac-scanning.md](docs/setup/16-iac-scanning.md) |
| **SBOM** / **SPDX** | [17-sbom-attestations.md](docs/setup/17-sbom-attestations.md) |
| **eBPF** | [18-runtime-security.md](docs/setup/18-runtime-security.md) |
| **PSA** / **ACL** (Key Vault) | [19-namespace-hardening.md](docs/setup/19-namespace-hardening.md) |
| **DAST** / **ZAP** / **OWASP** | [20-dast.md](docs/setup/20-dast.md) |
| **DevSecOps** (Phase 15+ plan) | [phase15-plus.md](docs/implementation/phase15-plus.md) |

Wave 1 and Wave 2 terms expand **once** in their home document; later mentions use the abbreviation alone.

## Code style

- Terraform: `terraform fmt` (enforced by pre-commit).
- YAML: yamllint for `gitops/`, `policies/`, `pipelines/`.
- Shell scripts: `kebab-case`, verb-first names; include header comment.

## Commits

Use clear messages focused on **why**:

```text
phase-3: provision AKS with germanywestcentral node SKUs

Wire aks module with Standard_D2s_v6 system pool and Standard_D4s_v6 user pool.
```

## Approval gates

Architecture, plan, and structure are approved. Implementation proceeds phase-by-phase with explicit confirmation after each validation.
