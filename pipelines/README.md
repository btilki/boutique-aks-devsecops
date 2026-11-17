# Pipelines

## CI story

| | |
|--|--|
| CI platform | Azure DevOps |
| Git remote | GitHub (this repo — not Azure Repos) |
| GitHub Actions | **Not used** (no `.github/workflows`) |

ADO checkouts this GitHub repository, mirrors/scans/signs images into ACR (OIDC), and can commit digest pins back to Git for Argo CD.

## Purpose

Mirror Online Boutique, Trivy CRITICAL gate, cosign sign (`--tlog-upload=false`), digest promotion. Pin: [`versions.yaml`](../versions.yaml).

Trivy, cosign, and Kustomize in the supply-chain and promote jobs are pinned release assets. Each download is checked with `sha256sum` against the checksum file published with that release.

## Contents

| File | Role |
|------|------|
| `azure-pipelines.yml` | Main supply-chain pipeline (`main` push; `pr: none`) |
| `azure-pipelines-promote.yml` | Digest promotion pipeline (stage/prod; Topic 12) |
| `azure-pipelines-pr.yml` | PR validation pipeline (Topic 14) |
| `azure-pipelines-dast.yml` | Optional ZAP baseline DAST (manual) — Topic 20 |
| `templates/variables.yml` | Versions, ACR/KV names, service list |
| `templates/dast-variables.yml` | ZAP image + target defaults |
| `templates/dast-zap.yml` | ZAP baseline job |
| `templates/pr-variables.yml` | PR pipeline tool pins (Terraform / Checkov / Kyverno CLI / Python) |
| `templates/pr-validate.yml` | PR validation jobs |
| `templates/build-scan-sign.yml` | Mirror / scan / sign; SPDX attest when `enableSbomAttest=true` (Topic 17; default off) |
| `templates/promote-digest.yml` | GitOps overlay digest updates |

## Prerequisites

| Pipeline | Needs |
|----------|--------|
| Supply-chain / promote | ADO OIDC (Topic 04), ACR + KV (Topic 03), GitHub↔ADO (Topic 09) |
| PR validate | GitHub↔ADO only — **no** OIDC/ACR (Topic 14) |
| DAST (ZAP) | Live HTTPS Boutique URL; Docker on agent (Topic 20) — **no** OIDC |

## Usage

[docs/setup/09-ci-pipeline.md](../docs/setup/09-ci-pipeline.md) · [docs/setup/14-pr-ci.md](../docs/setup/14-pr-ci.md) · [docs/setup/12-promotion-stage-prod.md](../docs/setup/12-promotion-stage-prod.md) · [docs/setup/20-dast.md](../docs/setup/20-dast.md)

Local equivalent of PR gates: `make pr-validate` or `./tests/ci/pr-validate.sh`. Checkov only: `make checkov`. Local DAST (live URL): `./tests/ci/dast-zap.sh`.

## Timing

Topic 09: main pipeline (mirror → Trivy → cosign; `enableSbomAttest` default off). Topic 12: promote. Topic 14/16: PR + Checkov. Topic 17: set `enableSbomAttest=true` for SBOM attest. Topic 20: optional ZAP DAST (manual).
