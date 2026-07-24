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

On the **first mention** of a term in the document that **most closely relates** to it, write the **abbreviation first**, then the full form in **parentheses and bold**:

```markdown
SBOM (**Software Bill of Materials**)
```

Later mentions in that document (and in other docs) may use the abbreviation alone.

| Abbreviation | Full form | Primary document |
|--------------|-----------|------------------|
| AKS | Azure Kubernetes Service | [docs/setup/03-cluster-resources.md](docs/setup/03-cluster-resources.md) |
| ACR | Azure Container Registry | [docs/setup/03-cluster-resources.md](docs/setup/03-cluster-resources.md) |
| ADO | Azure DevOps | [docs/setup/04-ado-oidc.md](docs/setup/04-ado-oidc.md) |
| OIDC | OpenID Connect | [docs/setup/04-ado-oidc.md](docs/setup/04-ado-oidc.md) |
| UAMI | User-Assigned Managed Identity | [docs/setup/04-ado-oidc.md](docs/setup/04-ado-oidc.md) |
| RBAC | Role-Based Access Control | [docs/setup/03-cluster-resources.md](docs/setup/03-cluster-resources.md) |
| CSI | Container Storage Interface | [docs/setup/07-secrets-csi.md](docs/setup/07-secrets-csi.md) |
| TLS | Transport Layer Security | [docs/setup/06-ingress-tls.md](docs/setup/06-ingress-tls.md) |
| CNI | Container Network Interface | [docs/architecture/06-network-design.md](docs/architecture/06-network-design.md) |
| NSG | Network Security Group | [docs/architecture/06-network-design.md](docs/architecture/06-network-design.md) |
| NPM | Network Policy Manager | [docs/setup/15-network-policies.md](docs/setup/15-network-policies.md) |
| PR | Pull Request | [docs/setup/14-pr-ci.md](docs/setup/14-pr-ci.md) |
| CI | Continuous Integration | [docs/setup/14-pr-ci.md](docs/setup/14-pr-ci.md) |
| IaC | Infrastructure as Code | [docs/setup/16-iac-scanning.md](docs/setup/16-iac-scanning.md) |
| SBOM | Software Bill of Materials | [docs/setup/17-sbom-attestations.md](docs/setup/17-sbom-attestations.md) |
| SPDX | Software Package Data Exchange | [docs/setup/17-sbom-attestations.md](docs/setup/17-sbom-attestations.md) |
| eBPF | extended Berkeley Packet Filter | [docs/setup/18-runtime-security.md](docs/setup/18-runtime-security.md) |
| PSA | Pod Security Admission | [docs/setup/19-namespace-hardening.md](docs/setup/19-namespace-hardening.md) |
| ACL | Access Control List | [docs/setup/19-namespace-hardening.md](docs/setup/19-namespace-hardening.md) |
| DAST | Dynamic Application Security Testing | [docs/setup/20-dast.md](docs/setup/20-dast.md) |
| ZAP | Zed Attack Proxy | [docs/setup/20-dast.md](docs/setup/20-dast.md) |
| DevSecOps | Development, Security, and Operations | [README.md](README.md) |

Do **not** expand ubiquitous file/format tokens (`YAML`, `JSON`, `HTTP`, `HTTPS`, `DNS`) unless the doc is introducing them to beginners.

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
