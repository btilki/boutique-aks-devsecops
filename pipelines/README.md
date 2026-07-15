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
| `azure-pipelines.yml` | Main supply-chain pipeline |
| `azure-pipelines-promote.yml` | Stage → prod promotion (ADO env approval on prod) |
| `templates/variables.yml` | Versions, ACR/KV names, service list |
| `templates/build-scan-sign.yml` | Mirror / scan / sign |
| `templates/promote-digest.yml` | GitOps overlay digest updates |

## Prerequisites

- ADO OIDC (Topic 04) — service connection `azure-boutique-oidc`
- ACR + Key Vault (Topic 03)
- GitHub repo connected to the ADO project (Topic 09)

## Usage

[docs/setup/09-ci-pipeline.md](../docs/setup/09-ci-pipeline.md) · [docs/setup/12-promotion-stage-prod.md](../docs/setup/12-promotion-stage-prod.md)

## Timing

Topic 09: main pipeline. Topic 12: promote pipeline + stage/prod overlays.
