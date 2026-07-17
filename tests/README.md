# Tests — boutique-aks-devsecops

**Maturity target:** Production pilot (single AKS cluster test)
**Authority:** [ROADMAP.md](../ROADMAP.md), [docs/implementation/plan.md](../docs/implementation/plan.md), [docs/architecture/01-requirements.md](../docs/architecture/01-requirements.md)

This directory holds **runnable** validation. Empty folders are intentional placeholders until scripts exist (do not invent greenwash tests).

---

## Quick start — P0 before push

From repo root (macOS/Linux, tools from Topic 00):

```bash
# Lint + secrets + Terraform validate (local CI baseline)
make pre-commit

# Terraform fmt + validate (bootstrap + environments/dev)
./tests/terraform/validate.sh

# Kyverno unit tests (needs: brew/curl install kyverno CLI)
kyverno test policies/tests

# After live cluster exists — smokes (need kubectl + DNS/TLS)
./tests/integration/promotion-smoke.sh all
# Optional: ./tests/integration/dev-smoke.sh
# Optional: ./tests/integration/rollback-smoke.sh stage
```

Post-apply foundation (Topic 03+) — needs `az` login + Terraform outputs:

```bash
./tests/terraform/foundation-post-apply.sh
```

---

## Layout

| Path | Purpose | Status |
|------|---------|--------|
| `terraform/validate.sh` | `fmt -check` + `validate` | **Runnable** |
| `terraform/foundation-post-apply.sh` | AKS/ACR/KV post-apply smoke | **Runnable** (needs Azure) |
| `integration/dev-smoke.sh` | Dev HTTPS + pods | **Runnable** (needs cluster) |
| `integration/promotion-smoke.sh` | Stage/prod HTTPS | **Runnable** (needs cluster) |
| `integration/rollback-smoke.sh` | Post-revert HTTPS | **Runnable** (needs cluster) |
| `kubernetes/` | kubeconform / schema | **Empty** — backlog |
| `policies/` | wrapper → Kyverno | **Empty** — use `policies/tests/` |
| [policies/tests/](../policies/tests/) | Kyverno CLI unit tests | **Runnable** |

---

## Test ID map (P0)

| ID | Command / tool | When |
|----|----------------|------|
| TEST-001 | `pre-commit` trailing/YAML/large-files | Local / before commit |
| TEST-002 | `terraform fmt -check` via `validate.sh` | Local / pre-commit |
| TEST-003 | `terraform validate` via `validate.sh` | Local / pre-commit |
| TEST-004 | `gitleaks` via pre-commit | Local / before commit |
| TEST-005 | `yamllint` on `gitops|policies|pipelines` | Local / pre-commit |
| TEST-006 | `kyverno test policies/tests` | Local (Kyverno CLI) |
| TEST-007 | ADO Validate stage + Mirror/scan/sign | `main` push (ADO) |
| TEST-008 | `./tests/integration/dev-smoke.sh` | Post Topic 10 / manual |
| TEST-009 | `./tests/integration/promotion-smoke.sh all` | Post Topic 12 / manual |
| TEST-010 | Argo CD Synced+Healthy (manual/`kubectl`) | Post GitOps / manual |
| TEST-011 | `./tests/terraform/foundation-post-apply.sh` | Post Topic 03 / manual |
| TEST-012 | `./tests/integration/rollback-smoke.sh <env>` | Rollback drill / manual |

---

## CI/CD (Azure DevOps)

There is **no GitHub Actions** CI for this repo. Gates:

| Trigger | Pipeline | Tests |
|---------|----------|-------|
| Push `main` (paths: pipelines, versions, boutique gitops) | `pipelines/azure-pipelines.yml` | Validate vars + Trivy CRITICAL + cosign (TEST-007) |
| Manual / promote | `pipelines/azure-pipelines-promote.yml` | Digest promote (stage/prod) |
| Local hook | `.pre-commit-config.yaml` | TEST-001–005 |

**Gap:** PR trigger is `pr: none` on supply-chain pipeline — static checks are local/pre-commit only unless you add an ADO PR pipeline.

---

## Maturity notes

| Category | Pilot bar | This repo |
|----------|-----------|-----------|
| Terraform validate/fmt | Required | Yes |
| Manifest schema (kubeconform) | Required | **Missing** |
| Policy checks (Kyverno) | Required | Yes (unit); live dry-run ad hoc |
| Integration / smoke | Required | Yes (dev/stage/prod) |
| Basic load | Pilot | **Waived** — loadgenerator scaled to 0 for capacity |
| Chaos / DR drill | Enterprise / roadmap | **Out of scope** for test teardown path |

---

## Related docs

- Setup validation: [docs/setup/](../docs/setup/)
- Troubleshooting: [docs/troubleshooting/](../docs/troubleshooting/)
- Screenshots of green paths: [assets/images/setup/](../assets/images/setup/)
