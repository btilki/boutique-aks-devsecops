# CI contract — boutique-aks-devsecops

Audience: Implementer or reviewer · Lived path: Topic 09 (+ promote in Topic 12) · ADR [0005](adr/0005-cosign-key-based-signing.md), [0009](adr/0009-mirror-upstream-images.md) · Full inventory: [`pipelines/README.md`](../pipelines/README.md)

This page is the **lived** CI contract (mirror → scan → sign → digest promote). Extra pipelines (PR gates, Checkov, SBOM attest, DAST) live under [`pipelines/`](../pipelines/) and optional setup guides after rebuild — see [setup README](setup/README.md#optional-after-rebuild--not-part-of-the-closed-reference).

## After teardown

The closed reference left no live ACR and no live ADO OIDC federation. Rebuild Topics 03–04 before you expect mirror or sign jobs to succeed.

Pipeline YAML stays in Git under [`pipelines/`](../pipelines/). After a rebuild, register and run it in Azure DevOps — see [setup/09-ci-pipeline.md](setup/09-ci-pipeline.md).

## At a glance

| | |
|--|--|
| Git | GitHub (source of truth for Argo CD) |
| CI | Azure DevOps (OIDC to Azure) |
| GitHub Actions | Not used |
| Lived path | Mirror Boutique → Trivy CRITICAL → cosign sign → digest in Git |
| Hard rule | **Unsigned or floating tags should not reach the cluster** |

## Hard rules

| Rule | Detail |
|------|--------|
| No long-lived Azure secrets in the pipeline | ADO OIDC federated credential |
| Images are mirrored, not rebuilt from Boutique source | ADR-0009 |
| Trivy fails the job on CRITICAL | `--ignore-status fixed` is a reference compromise — see [reference-claims.md](reference-claims.md) |
| cosign signs by digest with `--tlog-upload=false` | ADR-0005; Kyverno ignores the transparency log and SCT to match |
| Tool installs are checksum-verified | Trivy, cosign, and Kustomize release assets checked with `sha256sum` |
| Prod promote needs human approval | ADO environment approval (ADR-0008) |

## Pipeline map (lived path)

| Pipeline / template | Role | Setup |
|---------------------|------|--------|
| `azure-pipelines.yml` | Mirror, scan, sign | Topic 09 |
| `azure-pipelines-promote.yml` | Promote digests (uses `templates/promote-digest.yml`) | Topic 12 |
| `templates/promote-digest.yml` | Commit digests into overlays | Topic 12 |

Full file list (including PR / DAST YAML): [`pipelines/README.md`](../pipelines/README.md).

## Where to go next

| Need | Open |
|------|------|
| Full CI story and file list | [`pipelines/README.md`](../pipelines/README.md) |
| Setup steps for a rebuild | [setup/09-ci-pipeline.md](setup/09-ci-pipeline.md) |
| Promotion after digests exist | [promotion.md](promotion.md) |
| What the reference proved | [reference-claims.md](reference-claims.md) |
