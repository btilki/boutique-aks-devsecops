# Pipelines

## Purpose

Azure DevOps pipeline definitions: mirror Online Boutique v0.10.5, Trivy scan, cosign sign, digest promotion. Pipelines run in **Azure DevOps** but read and push YAML/manifests from **GitHub** (not Azure Repos).

## Contents

- `azure-pipelines.yml` — main pipeline
- `templates/variables.yml` — region, ACR, hostnames from `versions.yaml`
- `templates/build-scan-sign.yml` — mirror/scan/sign stages
- `templates/promote-digest.yml` — stage/prod promotion (Phase 12)

## Prerequisites

- ADO OIDC configured (Phase 4)
- ACR exists (Phase 3)
- GitHub repository connected to ADO (Topic 09 Step 9.5)

## Usage

[docs/setup/09-ci-pipeline.md](../docs/setup/09-ci-pipeline.md)

## Timing

Topic 09: `azure-pipelines.yml`, `templates/*.yml`, setup guide.  
Topic 12: `azure-pipelines-promote.yml`, stage/prod overlays, promotion smoke tests.
