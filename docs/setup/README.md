# Setup Guide — boutique-aks-devsecops

Audience: Implementer
Authority: This directory is the **single source of truth** for bootstrap. If README, chat, or scripts conflict with `docs/setup/`, this guide wins.
[Doc index](../README.md) · [Architecture summary](../../ARCHITECTURE.md) · [Roadmap](../../ROADMAP.md) · [Reference claims](../reference-claims.md)

> **Reference status:** Production reference closed. Setup Topics **00–13** ran end to end; then Azure resources from that run were destroyed.
> There is no live AKS, ACR, Key Vault, or Terraform-managed platform from the reference.
> This guide is for step-by-step rebuild and validation. Follow Topics **00 → 13** in order unless you abort early (still use Topic 13 teardown order).
> Do not assume a cluster already exists because the repo is complete in Git.

---

## 1. Overview

### What this guide achieves

End-to-end bootstrap of a production-reference Azure DevSecOps platform for Online Boutique **v0.10.5** on one AKS cluster in `germanywestcentral`:

1. Remote Terraform state and Azure foundation (VNet, DNS, AKS, ACR, Key Vault)
2. ADO OIDC federation (no long-lived CI secrets)
3. GitOps platform (Argo CD, ingress, TLS, CSI, Kyverno, monitoring)
4. Secure supply chain (mirror → Trivy → cosign → Kyverno verify)
5. Boutique deployment across dev / stage / prod namespaces
6. Observability, promotion gates, integration validation, and teardown

### Estimated time and cost

| Scope | Time (solo) | Cost impact |
|-------|-------------|-------------|
| Topics 00–05 (foundation + GitOps) | ~8–12 hours | Low until AKS (Topic 03) |
| Topics 06–10 (platform + CI + dev app) | ~10–14 hours | AKS + ACR + Loki PVC ~€150–250/mo |
| Topics 11–12 (observability + promotion) | ~6–8 hours | Same cluster |
| Topic 13 (teardown) | ~1–2 hours | Destroys billable resources |

Times assume familiarity with Azure, Terraform, and Kubernetes. First-time builders should add 30–50%.

### Environments covered

| Logical env | K8s namespace | Ingress hostname | Argo sync | Prod gate |
|-------------|---------------|------------------|-----------|-----------|
| dev | `boutique-dev` | `dev-boutique.biroltilki.art` | Automatic | — |
| stage | `boutique-stage` | `stage-boutique.biroltilki.art` | Manual | — |
| prod | `boutique-prod` | `boutique.biroltilki.art` | Manual | ADO environment approval |

Physical platform: one AKS cluster from `terraform/environments/dev/`.

Platform hostnames (when rebuilt): `argocd-boutique.biroltilki.art`, `grafana-boutique.biroltilki.art`

---

## 2. Topic sequence (reference path: 00–13)

| # | Topic | Guide | Phase | Prerequisites | Est. time | Status |
|---|-------|-------|-------|---------------|-----------|--------|
| 00 | Prerequisites | [00-prerequisites.md](00-prerequisites.md) | 0 | None | 60 min | ✅ |
| 01 | Terraform bootstrap | [01-terraform-bootstrap.md](01-terraform-bootstrap.md) | 1 | 00 | 60 min | ✅ |
| 02 | Azure foundation | [02-azure-foundation.md](02-azure-foundation.md) | 2 | 01 | 90 min | ✅ |
| 03 | Cluster resources (AKS, ACR, KV) | [03-cluster-resources.md](03-cluster-resources.md) | 3 | 02 | 120 min | ✅ |
| 04 | ADO OIDC federation | [04-ado-oidc.md](04-ado-oidc.md) | 4 | 03 | 75 min | ✅ |
| 05 | GitOps bootstrap | [05-gitops-bootstrap.md](05-gitops-bootstrap.md) | 5 | 03 | 90 min | ✅ |
| 06 | Ingress + TLS | [06-ingress-tls.md](06-ingress-tls.md) | 6 | 05 | 120 min | ✅ |
| 07 | Secrets Store CSI | [07-secrets-csi.md](07-secrets-csi.md) | 7 | 03, 05 | 75 min | ✅ |
| 08 | Admission policies (Kyverno) | [08-admission-policies.md](08-admission-policies.md) | 8 | 05, 09† | 120 min | ✅ |
| 09 | CI pipeline (mirror, scan, sign) | [09-ci-pipeline.md](09-ci-pipeline.md) | 9 | 04, 03 | 180 min | ✅ |
| 10 | Boutique dev deploy | [10-boutique-dev.md](10-boutique-dev.md) | 10 | 06, 08, 09 | 90 min | ✅ |
| 11 | Observability | [11-observability.md](11-observability.md) | 11 | 05, 10 | 90 min | ✅ |
| 12 | Promotion (stage + prod) | [12-promotion-stage-prod.md](12-promotion-stage-prod.md) | 12 | 10, 11 | 120 min | ✅ |
| 13 | Teardown | [13-teardown.md](13-teardown.md) | 14 | 12 | 60 min | ✅ |

† Topic 08 note: Kyverno installs after GitOps bootstrap (05). Signature verification is validated after CI (09) produces signed digests. Topic 08 covers install and baseline policies; the verify step points at Topic 09.

Status legend: ⬜ Not started · 🔄 In progress · ✅ Complete

Dependency chain: `00 → 01 → 02 → 03 → 04 → 05 → 06 → 07` and `03 → 09 → 08 → 10 → 11 → 12 → 13`

This is the reference story. Live execution through Topic 12 is complete; Topic 13 destroyed the platform.

### Optional after rebuild — not part of the closed reference

Guides 14–20 exist in Git as scaffolds only. They were not required for Topics 00–13 and are not claimed as demonstrated. Enable only after a deliberate rebuild; see [ROADMAP](../../ROADMAP.md) · [phase15-plus.md](../implementation/phase15-plus.md).

| # | Topic | Guide |
|---|--------|-------|
| 14 | PR CI gates | [14-pr-ci.md](14-pr-ci.md) |
| 15 | NetworkPolicies | [15-network-policies.md](15-network-policies.md) |
| 16 | IaC scanning | [16-iac-scanning.md](16-iac-scanning.md) |
| 17 | SBOM + attestations | [17-sbom-attestations.md](17-sbom-attestations.md) |
| 18 | Runtime security | [18-runtime-security.md](18-runtime-security.md) |
| 19 | Namespace / KV hardening | [19-namespace-hardening.md](19-namespace-hardening.md) |
| 20 | DAST (optional) | [20-dast.md](20-dast.md) |

---

## 3. Conventions

### Shell and OS

- Shell: bash or zsh on macOS or Linux (WSL2 is fine)
- Working directory: repository root unless a step says otherwise
- Commands are copy-paste ready; do not shorten flags when you run them

### Azure

| Setting | Value |
|---------|-------|
| Cloud | Azure only |
| Region | `germanywestcentral` |
| DNS zone | `biroltilki.art` (Azure DNS) |
| Subscription | Your test subscription — see placeholder below |

### Placeholder legend

Replace placeholders in commands and `terraform.tfvars` with your values:

Version control: Git lives on GitHub only. `<ADO_ORG>` / `<ADO_PROJECT>` are the Azure DevOps org and project for pipelines and OIDC — not a Git remote.

| Placeholder | Meaning | Example |
|-------------|---------|---------|
| `<SUBSCRIPTION_ID>` | Azure subscription GUID | `00000000-0000-0000-0000-000000000000` |
| `<TENANT_ID>` | Entra ID tenant GUID | from `az account show` |
| `<RESOURCE_GROUP>` | Platform resource group name | `rg-boutique-dev-gwc` |
| `<LOCATION>` | Azure region | `germanywestcentral` |
| `<CLUSTER_NAME>` | AKS cluster name | `aks-boutique-dev-gwc` |
| `<ACR_NAME>` | ACR registry name (no domain) | `acrboutiquedevgwc` |
| `<KEY_VAULT_NAME>` | Key Vault name | `kv-boutique-dev-gwc` |
| `<DNS_ZONE>` | Public DNS zone | `biroltilki.art` |
| `<GITHUB_ORG>` | GitHub user or organization (VCS) | `your-github-user` |
| `<REPO_NAME>` | GitHub repository name | `boutique-aks-devsecops` |
| `<GITHUB_REPO_URL>` | GitHub HTTPS clone URL | `https://github.com/your-github-user/boutique-aks-devsecops.git` |
| `<ADO_ORG>` | ADO organization slug (CI/OIDC only) | `yourorg` |
| `<ADO_PROJECT>` | ADO project name (pipelines) | `boutique-aks-devsecops` |
| `<TF_STATE_RG>` | Bootstrap state resource group | `rg-tfstate-boutique-gwc` |
| `<TF_STATE_STORAGE>` | Bootstrap storage account | `stboutiquetfgwc` |
| `<TF_STATE_CONTAINER>` | State blob container | `tfstate` |

**Never commit** real `terraform.tfvars`, cosign keys, or service-principal secrets.

### Local state and credentials

| Artifact | Typical location |
|----------|------------------|
| Azure CLI session | `~/.azure/` |
| kubeconfig (AKS) | `~/.kube/config` (context after Topic 03) |
| Terraform state | Remote blob — not in Git (Topic 01) |
| cosign key pair | Key Vault or a secure local path (Topic 09) — not in Git |
| ADO PAT (if any) | Prefer OIDC for Azure; use a PAT only for GitHub access that OIDC cannot cover |

### Version pins

All platform versions: [versions.yaml](../../versions.yaml). Setup topics reference this file; do not hardcode divergent versions in guides.

---

## 4. Getting help

### Troubleshooting index

| Symptom area | Guide |
|--------------|-------|
| ADO OIDC / federation | [docs/troubleshooting/ado-oidc.md](../troubleshooting/ado-oidc.md) |
| Argo CD sync | [docs/troubleshooting/argocd-sync.md](../troubleshooting/argocd-sync.md) |
| cert-manager DNS-01 | [docs/troubleshooting/cert-manager-dns01.md](../troubleshooting/cert-manager-dns01.md) |
| Image signature / Kyverno | [docs/troubleshooting/image-signature.md](../troubleshooting/image-signature.md) |
| Kyverno admission | [docs/troubleshooting/kyverno-admission.md](../troubleshooting/kyverno-admission.md) |
| Pipeline failures | [docs/troubleshooting/pipeline-failures.md](../troubleshooting/pipeline-failures.md) |
| Promotion failures | [docs/troubleshooting/promotion-failures.md](../troubleshooting/promotion-failures.md) |
| Monitoring / alerting | [docs/troubleshooting/monitoring-alerting.md](../troubleshooting/monitoring-alerting.md) |

### How to report a failed step

When asking for help, include:

1. Topic and step — e.g. `03-cluster-resources`, Step 3.2
2. Command or GUI action — exact input
3. Full terminal output or a screenshot of the Azure Portal / ADO error
4. The validation command that failed
5. Placeholder values you used (redact secrets)

### Related documentation

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE.md](../../ARCHITECTURE.md) | Executive architecture |
| [ROADMAP.md](../../ROADMAP.md) | Phase milestones |
| [docs/implementation/plan.md](../implementation/plan.md) | Implementation plan (maintainer) |
| [docs/architecture/](../architecture/) | Deep architecture series |
| [docs/adr/](../adr/) | Architecture decision records |

---

## 5. How to run a rebuild

Work one topic at a time. Finish the validation checklist before you open the next guide. Do not skip ahead. Do not replace documented steps with install-all scripts.

Hard rules: `docs/setup/` is authoritative · **never commit** secrets or real `terraform.tfvars` · tear down with Topic 13 when the test is done.

Stop at Topic 13 for a faithful repeat of the closed reference. Optional guides 14–20 are linked above — not on the critical path.

---

## 6. Progress tracker

Mark topics in the table in §2 as you complete them. Lived reference: Topics **00–13** executed; platform torn down; rebuild with this guide.

| Milestone | Topics | Target |
|-----------|--------|--------|
| Milestone 1: Repo & state | 00–01 | Remote Terraform state exists |
| Milestone 2: Azure foundation | 02–03 | `kubectl get nodes`; ACR push works |
| Milestone 3: Trust & GitOps | 04–05 | OIDC pipeline green; Argo CD healthy |
| Milestone 4: Platform services | 06–08 | TLS Ready; Kyverno enforces |
| Milestone 5: Secure delivery | 09–10 | Signed digest in ACR; dev app live |
| Milestone 6: Operate & promote | 11–12 | Grafana + SLO; prod promotion |
| Milestone 7: Complete & teardown | 13 | Teardown validated; ACR destroyed |
