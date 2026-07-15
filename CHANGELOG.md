# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- README **Limitations** blurb and consolidated **CI story** (GitHub VCS + Azure DevOps CI; no GitHub Actions) for public-share clarity.
- Morning checklist with Argo CD sync health as gate #1 in `docs/operations/08-health-checks.md`.
- `gitops/platform/monitoring/extras/README.md` — single source of truth for custom alerts/dashboards.
- Public-share hygiene section in CONTRIBUTING (no empty workflows, no “production-ready” claims, no badge grids).
- `.gitignore` coverage for Terraform local state, `.terraform/`, and `*.tfvars` (examples remain tracked).

### Changed

- Alert catalog docs point only at `gitops/platform/monitoring/extras/alerts/` (`docs/operations/10-alerting.md`, architecture observability).
- Fixed relative doc links from `terraform/` and `gitops/platform/monitoring/{loki,promtail}/` READMEs.

### Removed

- Orphan duplicate PrometheusRules / ServiceMonitors / dashboards under `kube-prometheus-stack/` and top-level `monitoring/dashboards/`.
- Empty `.github/workflows` (never used; CI remains Azure DevOps).

## [0.2.0] — 2026-07-15

Production-pilot lab through Setup Topics **00–12** (live), with Topic **13** teardown authored but not executed.

### Added

#### Setup guides (Topics 00–13)

- Complete `docs/setup/` index and guides for Topics **00–13**.
- Troubleshooting: ADO OIDC, Argo CD sync, cert-manager DNS-01, Kyverno, image signatures, pipelines, promotion, monitoring.
- Runbooks: promotion/rollback, teardown, incident response; ops manuals under `docs/operations/`.
- Security: supply chain, threat model, secrets management; SLO: Boutique availability.

#### Infrastructure (Terraform)

- Bootstrap remote state; modules for RG, networking, DNS, diagnostics, AKS, ACR, Key Vault, identities, ADO OIDC federation.
- Single-cluster platform in `germanywestcentral` (`terraform/environments/dev/`).

#### GitOps platform

- Argo CD **2.10.7**, AppProjects, platform apps (ingress-nginx, cert-manager, CSI, Kyverno, monitoring, Loki/Promtail).
- Boutique base + **dev / stage / prod** overlays (auto-sync dev; manual stage/prod).

#### CI / supply chain

- **Azure DevOps** pipelines: mirror Boutique **v0.10.5** → ACR, Trivy CRITICAL gate, cosign sign (`--tlog-upload=false`), promote digests.
- Kyverno: ACR allowlist, deny `:latest`, verifyImages, PSS baseline, no privileged/hostPath.

#### Operations & tests

- `scripts/operations/teardown.sh` (ADR-0010 destroys ACR).
- Integration smokes: `dev-smoke.sh`, `promotion-smoke.sh`, `rollback-smoke.sh`.
- Policy unit tests under `policies/tests/`.

### Changed

- Node pools on live lab: `Standard_D2s_v6` / `Standard_D4s_v6` where quota required (see ADR-0011).
- Monitoring/Boutique sized for a two-node lab; alerts consolidated under `monitoring/extras/`.

### Fixed

- Cosign verify `--insecure-ignore-tlog` aligned with key-based signing (ADR-0005).
- Kyverno 3.x `verifyImages` schema; Topic 11 sync unblockers (OTel, AppProject destinations, ACR excludes).

## [0.1.0] — 2026-07-14

### Added

- Phase 0 repository scaffold: architecture docs, structure, `versions.yaml`, pre-commit.
- Locked region `germanywestcentral`, Online Boutique **v0.10.5**, and five public hostnames on `biroltilki.art`.
