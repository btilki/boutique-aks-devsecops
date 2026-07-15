# Setup Guide — boutique-aks-devsecops

**Authority:** If README, chat, or scripts conflict with this directory, **`docs/setup/` wins**.

**Audience:** L2 implementer following topics manually, one step at a time, with validation after every step.

**Status:** Phase B **complete** — Topics **00–13** guides and repo files materialized.

---

## 1. Overview

### What this guide achieves

End-to-end bootstrap of a **production-pilot Azure DevSecOps platform** for **Online Boutique v0.10.5** on a **single AKS cluster** in `germanywestcentral`:

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
| Topics 06–10 (platform + CI + dev app) | ~10–14 hours | **AKS + ACR + LAW** ~€150–250/mo |
| Topics 11–12 (observability + promotion) | ~6–8 hours | Same cluster |
| Topic 13 (teardown) | ~1–2 hours | Destroys billable resources |

Times assume familiarity with Azure, Terraform, and Kubernetes. First-time builders should add 30–50%.

### Environments covered

| Logical env | K8s namespace | Ingress hostname | Argo sync | Prod gate |
|-------------|---------------|------------------|-----------|-----------|
| dev | `boutique-dev` | `dev-boutique.biroltilki.art` | Automatic | — |
| stage | `boutique-stage` | `stage-boutique.biroltilki.art` | Manual | — |
| prod | `boutique-prod` | `boutique.biroltilki.art` | Manual | ADO environment approval |

**Physical platform:** one AKS cluster provisioned via `terraform/environments/dev/`.

**Platform hostnames:** `argocd-boutique.biroltilki.art`, `grafana-boutique.biroltilki.art`

---

## 2. Topic sequence

| # | Topic | Guide | Phase | Prerequisites | Est. time | Status |
|---|-------|-------|-------|---------------|-----------|--------|
| 00 | Prerequisites | [00-prerequisites.md](00-prerequisites.md) | 0 | None | 60 min | 🔄 |
| 01 | Terraform bootstrap | [01-terraform-bootstrap.md](01-terraform-bootstrap.md) | 1 | 00 | 60 min | ⬜ |
| 02 | Azure foundation | [02-azure-foundation.md](02-azure-foundation.md) | 2 | 01 | 90 min | ⬜ |
| 03 | Cluster resources (AKS, ACR, KV) | [03-cluster-resources.md](03-cluster-resources.md) | 3 | 02 | 120 min | ⬜ |
| 04 | ADO OIDC federation | [04-ado-oidc.md](04-ado-oidc.md) | 4 | 03 | 75 min | ⬜ |
| 05 | GitOps bootstrap | [05-gitops-bootstrap.md](05-gitops-bootstrap.md) | 5 | 03 | 90 min | ⬜ |
| 06 | Ingress + TLS | [06-ingress-tls.md](06-ingress-tls.md) | 6 | 05 | 120 min | ⬜ |
| 07 | Secrets Store CSI | [07-secrets-csi.md](07-secrets-csi.md) | 7 | 03, 05 | 75 min | ⬜ |
| 08 | Admission policies (Kyverno) | [08-admission-policies.md](08-admission-policies.md) | 8 | 05, 09† | 120 min | ✅ |
| 09 | CI pipeline (mirror, scan, sign) | [09-ci-pipeline.md](09-ci-pipeline.md) | 9 | 04, 03 | 180 min | ✅ |
| 10 | Boutique dev deploy | [10-boutique-dev.md](10-boutique-dev.md) | 10 | 06, 08, 09 | 90 min | ✅ |
| 11 | Observability | [11-observability.md](11-observability.md) | 11 | 05, 10 | 90 min | ⬜ |
| 12 | Promotion (stage + prod) | [12-promotion-stage-prod.md](12-promotion-stage-prod.md) | 12 | 10, 11 | 120 min | ⬜ |
| 13 | Teardown | [13-teardown.md](13-teardown.md) | 14 | 12 | 60 min | ⬜ |

† **Topic 08 note:** Kyverno installs after GitOps bootstrap (05). Image signature verification policy is validated after CI (09) produces signed digests. Topic 08 covers install + baseline policies; signature verify step references Topic 09.

**Status legend:** ⬜ Not started · 🔄 In progress · ✅ Complete

**Dependency chain:** `00 → 01 → 02 → 03 → 04 → 05 → 06 → 07` and `03 → 09 → 08 → 10 → 11 → 12 → 13`

**Phase 13 (hardening & integration)** has no separate setup topic — validation runs via `tests/integration/` after Topic 12.

---

## 3. Conventions

### Shell and OS

- **Shell:** bash or zsh on **macOS** or **Linux** (WSL2 acceptable)
- **Working directory:** repository root unless a step says otherwise
- Commands are copy-paste ready; do not abbreviate flags in live execution

### Azure

| Setting | Value |
|---------|-------|
| Cloud | Azure only |
| Region | `germanywestcentral` (Germany West Central) |
| DNS zone | `biroltilki.art` (Azure DNS) |
| Subscription | Your lab subscription — see placeholder below |

### Placeholder legend

Replace placeholders in commands and `terraform.tfvars` with your values:

**Version control:** Git lives on **GitHub** only. `<ADO_ORG>` / `<ADO_PROJECT>` refer to the Azure DevOps **organization and project for pipelines and OIDC** — not a Git remote.

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

**Never commit** real `terraform.tfvars`, cosign keys, or service principal secrets.

### Local state and credentials

| Artifact | Typical location |
|----------|------------------|
| Azure CLI session | `~/.azure/` |
| kubeconfig (AKS) | `~/.kube/config` (context after Topic 03) |
| Terraform state | Remote blob — **not** in Git (Topic 01) |
| cosign key pair | Key Vault or secure local path (Topic 09) — **not** in Git |
| ADO PAT (if any) | Argo CD GitHub read access only; pipeline uses GitHub connection — prefer OIDC for Azure |

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

Troubleshooting guides are authored incrementally in Phase B when each topic is written.

### How to report a failed step

When asking for help (chat or issue), include:

1. **Topic and step** — e.g. `03-cluster-resources`, Step 3.2
2. **Command or GUI action** — exact input used
3. **Full terminal output** or screenshot of Azure Portal / ADO error
4. **Validation command** that failed
5. **Placeholder values** used (redact secrets)

### Related documentation

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE.md](../../ARCHITECTURE.md) | Executive architecture |
| [ROADMAP.md](../../ROADMAP.md) | Phase milestones |
| [docs/implementation/plan.md](../implementation/plan.md) | Implementation plan |
| [docs/architecture/](../architecture/) | Deep architecture series |
| [docs/adr/](../adr/) | Architecture decision records |

---

## 5. Live implementation protocol

During **Phase C** (live execution), each turn follows:

1. **STATE** — current topic, step, last completed step
2. **FILE CHECK** — required files for this step (fix missing immediately)
3. **INSTRUCT** — commands and/or GUI (exact)
4. **VALIDATE** — expected output + validation commands
5. **WAIT** — stop until you confirm ✅ or report an error

**Hard rules:** one setup step per turn · no skip-ahead · no bypass scripts · `docs/setup/` is authoritative.

**Phase B** (after your approval of this catalog) authors each topic guide **and** creates all Required Files for that topic in one delivery per topic.

---

## 6. Phase A deliverables (this document)

Phase A (planning) produced:

- Setup topic catalog **00–13** with dependencies (see topic table above)
- This index and progress tracker
- Topic outlines and Required Files Inventory — **presented in Setup Chat for approval**
- **Stop** — Phase B begins only after explicit approval

**Approval phrase:** `Approved — begin Setup Phase B, Topic 01`

---

## 7. Progress tracker (update as you go)

Mark topics in the table in §2 when complete. Phase 0 scaffold (repo docs, lint config) is complete; Topic 00 guide is written.

| Milestone | Topics | Target |
|-----------|--------|--------|
| M1: Repo & state | 00–01 | Remote TF state exists |
| M2: Azure foundation | 02–03 | `kubectl get nodes`; ACR push works |
| M3: Trust & GitOps | 04–05 | OIDC pipeline green; Argo CD healthy |
| M4: Platform services | 06–08 | TLS Ready; Kyverno enforces |
| M5: Secure delivery | 09–10 | Signed digest in ACR; dev app live |
| M6: Operate & promote | 11–12 | Grafana + SLO; prod promotion |
| M7: Complete & teardown | 13 | Teardown validated; ACR destroyed |
