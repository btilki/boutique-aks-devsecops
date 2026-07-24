# Pipelines

## CI story

| | |
|--|--|
| **CI platform** | **Azure DevOps** |
| **Git remote** | **GitHub** (this repo — not Azure Repos) |
| **GitHub Actions** | **Not used** (no `.github/workflows`) |

ADO checkouts this GitHub repository, mirrors/scans/signs images into ACR (OIDC), and can commit digest pins back to Git for Argo CD.

## Purpose

Mirror Online Boutique **v0.10.5**, Trivy CRITICAL gate, cosign sign (`--tlog-upload=false`), digest promotion.

## Contents

| File | Role |
|------|------|
| `azure-pipelines.yml` | Main supply-chain pipeline (`main` push; `pr: none`) |
| `azure-pipelines-dast.yml` | Optional ZAP baseline DAST (manual) — Topic 20 |
| `templates/variables.yml` | Versions, ACR/KV names, service list |
| `templates/dast-variables.yml` | ZAP image + target defaults |
| `templates/dast-zap.yml` | ZAP baseline job |
| `templates/pr-variables.yml` | PR pipeline tool pins (Terraform / Kyverno CLI / Python) |
| `templates/pr-validate.yml` | PR validation jobs |
| `templates/build-scan-sign.yml` | Mirror / scan / sign / SPDX attest (Topic 17) |
| `templates/promote-digest.yml` | GitOps overlay digest updates |

## Prerequisites

| Pipeline | Needs |
|----------|--------|
| Supply-chain / promote | ADO OIDC (Topic 04), ACR + KV (Topic 03), GitHub↔ADO (Topic 09) |
| **PR validate** | GitHub↔ADO only — **no** OIDC/ACR (Topic 14) |
| **DAST (ZAP)** | Live HTTPS Boutique URL; Docker on agent (Topic 20) — **no** OIDC |

## Usage

[docs/setup/09-ci-pipeline.md](../docs/setup/09-ci-pipeline.md) · [docs/setup/14-pr-ci.md](../docs/setup/14-pr-ci.md) · [docs/setup/12-promotion-stage-prod.md](../docs/setup/12-promotion-stage-prod.md) · [docs/setup/20-dast.md](../docs/setup/20-dast.md)

Local equivalent of PR gates: `make pr-validate` or `./tests/ci/pr-validate.sh`. Checkov only: `make checkov`. Local DAST (live URL): `./tests/ci/dast-zap.sh`.

## Timing

Topic 09: main pipeline. Topic 12: promote. Topic 14/16: PR + Checkov. Topic 17: SBOM attest. Topic 20: optional ZAP DAST (manual).
