# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- **Phase 15+ plan:** [docs/implementation/phase15-plus.md](docs/implementation/phase15-plus.md), [ADR-0013](docs/adr/0013-scaffold-first-phase15.md) — scaffold-first fuller DevSecOps packages 1–8 without requiring live Azure.
- **Package 2 / Topic 14 (PR CI):** `pipelines/azure-pipelines-pr.yml`, `templates/pr-*.yml`, `tests/ci/pr-validate.sh`, `make pr-validate`, [docs/setup/14-pr-ci.md](docs/setup/14-pr-ci.md); `versions.yaml` `ci.*` pins.
- **Package 3 / Topic 15 (NetworkPolicies):** `gitops/apps/boutique/base/networkpolicies/`, optional `aks_network_policy` Terraform hook, [docs/setup/15-network-policies.md](docs/setup/15-network-policies.md).
- **Package 4 / Topic 16 (IaC scan):** Checkov `tests/terraform/.checkov.yaml` + PR job, [docs/setup/16-iac-scanning.md](docs/setup/16-iac-scanning.md); baseline skips for pilot tradeoffs.
- **Package 5 / Topic 17 (SBOM + attestations):** Trivy SPDX + cosign attest in `build-scan-sign.yml`, Kyverno `05-verify-sbom-attestation.yaml` (Audit), [ADR-0014](docs/adr/0014-sbom-cosign-attestations.md), [docs/setup/17-sbom-attestations.md](docs/setup/17-sbom-attestations.md).
- **Package 6 / Topic 18 (Runtime security):** Falco GitOps (`gitops/platform/falco/`), [ADR-0015](docs/adr/0015-falco-runtime-detection.md), Defender opt-in note, [docs/setup/18-runtime-security.md](docs/setup/18-runtime-security.md).
- **Package 7 / Topic 19 (Namespace + KV hardening):** PSA labels, ResourceQuota/LimitRange, KV ACL/purge TF options, [ADR-0016](docs/adr/0016-namespace-kv-hardening.md), [docs/setup/19-namespace-hardening.md](docs/setup/19-namespace-hardening.md).
- **Package 8 / Topic 20 (DAST):** Manual ZAP baseline pipeline, [ADR-0017](docs/adr/0017-optional-zap-dast.md), [docs/setup/20-dast.md](docs/setup/20-dast.md).
- **Phase 15+ scaffold complete** (Packages 1–8 / Topics 14–20).
- ROADMAP milestones M8a–M8e and Setup Topics **14–20** catalog in `docs/setup/README.md`.
- README **Limitations** blurb and consolidated **CI story** (GitHub VCS + Azure DevOps CI; no GitHub Actions) for public-share clarity.
- Morning checklist with Argo CD sync health as gate #1 in `docs/operations/08-health-checks.md`.
- `gitops/platform/monitoring/extras/README.md` — single source of truth for custom alerts/dashboards.
- Public-share hygiene section in CONTRIBUTING (no empty workflows, no “production-ready” claims, no badge grids).
- `.gitignore` coverage for Terraform local state, `.terraform/`, and `*.tfvars` (examples remain tracked).

### Changed

- Status SSOT: Topic **13** teardown executed (Azure destroyed); hostnames **Test offline** with screenshot proof; Phase 15+ Topics **14–20** scaffold documented.
- Documentation review: setup/ops/architecture indexes aligned with Phase 15+ + torn-down Azure; removed **Wave N** branding (use Topics / Phases / Packages only); CHANGELOG [0.2.0] historical note clarified.
- Terminology: environment wording standardized on **test** / **Test** (docs, comments, ops guides).
- Alert catalog docs point only at `gitops/platform/monitoring/extras/alerts/` (`docs/operations/10-alerting.md`, architecture observability).
- Fixed relative doc links from `terraform/` and `gitops/platform/monitoring/{loki,promtail}/` READMEs.

### Removed

- Orphan duplicate PrometheusRules / ServiceMonitors / dashboards under `kube-prometheus-stack/` and top-level `monitoring/dashboards/`.
- Empty `.github/workflows` (never used; CI remains Azure DevOps).

## [0.2.0] — 2026-07-15

Production-pilot through Setup Topics **00–12** (live at tag time). Topic **13** teardown guide was authored in this release and **executed later** (see Unreleased / current README status).

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

- Node pools on live test: `Standard_D2s_v6` / `Standard_D4s_v6` where quota required (see ADR-0011).
- Monitoring/Boutique sized for a two-node test; alerts consolidated under `monitoring/extras/`.

### Fixed

- Cosign verify `--insecure-ignore-tlog` aligned with key-based signing (ADR-0005).
- Kyverno 3.x `verifyImages` schema; Topic 11 sync unblockers (OTel, AppProject destinations, ACR excludes).

## [0.1.0] — 2026-07-14

### Added

- Phase 0 repository scaffold: architecture docs, structure, `versions.yaml`, pre-commit.
- Locked region `germanywestcentral`, Online Boutique **v0.10.5**, and five public hostnames on `biroltilki.art`.
