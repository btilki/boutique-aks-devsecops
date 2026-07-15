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
