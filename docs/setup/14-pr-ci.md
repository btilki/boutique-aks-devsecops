# 14 — PR CI Gates (shift-left validation)

**Audience:** L2 — Implementer
**Estimated time:** 45–60 minutes (ADO registration) + local dry-run
**Prerequisites:** [00-prerequisites.md](00-prerequisites.md) ✅ · [09-ci-pipeline.md](09-ci-pipeline.md) recommended (ADO + GitHub already connected)
**Creates:** Separate ADO pipeline from `pipelines/azure-pipelines-pr.yml`; optional branch policy requiring it
**Related:** [ADR-0013](../adr/0013-scaffold-first-phase15.md) · [phase15-plus.md](../implementation/phase15-plus.md) · [tests/README.md](../../tests/README.md)
**Mode:** Scaffold present in Git. Steps marked **Apply later** need a live ADO project (and optional live Azure only if you also rebuild Topics 00–12).

---

## Topic goal

When this topic is complete, **pull requests targeting `main`** run a dedicated Azure DevOps pipeline that fails on:

1. **pre-commit** (trailing whitespace, YAML, large files, Terraform fmt/validate hooks, yamllint, gitleaks)
2. **`tests/terraform/validate.sh`** (fmt -check + validate bootstrap + `environments/dev`)
3. **`tests/terraform/checkov.sh`** (Checkov on `terraform/` — Topic 16)
4. **`kyverno test policies/tests`** (admission policy unit tests)

The supply-chain pipeline (`azure-pipelines.yml`) stays on **`main` pushes only** (`pr: none`) — PRs do **not** mirror/scan/sign images.

## Why this topic is required

Without PR CI, broken Terraform, policy, or YAML can merge and only fail on `main` (or only on a laptop with pre-commit). Shift-left gates close the gap documented in [tests/README.md](../../tests/README.md).

---

## Before you begin

- [ ] Repo on **GitHub**; ADO project can checkout this GitHub repo (same as Topic 09)
- [ ] Local tools for dry-run: `pre-commit`, `terraform` (>= 1.6), `kyverno` CLI (~1.12.6)
- [ ] Scaffold files present (Package 2):

```bash
cd /path/to/boutique-aks-devsecops
ls -la pipelines/azure-pipelines-pr.yml \
  pipelines/templates/pr-validate.yml \
  pipelines/templates/pr-variables.yml \
  tests/ci/pr-validate.sh
```

**Expected:** all four paths exist.

---

## Step 14.1: Review PR pipeline layout

### Goal

Understand triggers, jobs, and what is intentionally out of scope.

### Why this step is required

Registering the wrong YAML (or enabling PR on the supply-chain pipeline) would either skip gates or attempt ACR/OIDC work on every PR.

### Commands

```bash
cd /path/to/boutique-aks-devsecops
cat pipelines/azure-pipelines-pr.yml
cat pipelines/templates/pr-variables.yml
head -n 40 pipelines/templates/pr-validate.yml
```

### Expected output

| File | Purpose |
|------|---------|
| `azure-pipelines-pr.yml` | `trigger: none`; `pr:` to `main` with path filters |
| `templates/pr-variables.yml` | Terraform / Kyverno CLI / Python pins |
| `templates/pr-validate.yml` | Three parallel jobs: PreCommit, TerraformValidate, KyvernoTest |

### Validation

- [ ] `pr.branches` includes `main`
- [ ] No `azureServiceConnection` / ACR / cosign in PR pipeline
- [ ] Main supply-chain file still has `pr: none`

```bash
grep -n "pr:" pipelines/azure-pipelines.yml pipelines/azure-pipelines-pr.yml
```

---

## Step 14.2: Local dry-run (no ADO required)

### Goal

Prove the same three gates pass on your workstation.

### Why this step is required

Catches tool/version issues before you debug ADO agents.

### Commands

```bash
cd /path/to/boutique-aks-devsecops
chmod +x tests/ci/pr-validate.sh   # once, if needed
./tests/ci/pr-validate.sh
# equivalent: make pr-validate
```

### Expected output

```text
[pr-validate] pre-commit --all-files
...
[pr-validate] terraform validate
[validate] OK
[pr-validate] kyverno test
...
[pr-validate] OK — same gates as azure-pipelines-pr.yml
```

### Validation

- [ ] Exit code 0
- [ ] Kyverno CLI version is compatible with policies (pin in `versions.yaml` → `ci.kyverno_cli`)

**Common problems:**

| Symptom | Fix |
|---------|-----|
| `kyverno: command not found` | Install CLI matching `ci.kyverno_cli` (see Topic 08 / Kyverno releases) |
| Terraform provider download fails offline | Need network for first `terraform init -backend=false` |
| pre-commit hook fails on vendored charts | Hooks already exclude Argo CD chart paths — do not widen blindly |

---

## Step 14.3: Register ADO pipeline — **Apply later**

### Goal

Create a **second** pipeline definition pointing at `pipelines/azure-pipelines-pr.yml`.

### Why this step is required

ADO does not auto-discover every YAML file. The Topic 09 supply-chain pipeline must stay separate so PRs never run mirror/Trivy/cosign.

### Commands / GUI

1. Azure DevOps → **Pipelines** → **New pipeline**
2. Select **GitHub** → this repository
3. **Existing Azure Pipelines YAML file** → path: `pipelines/azure-pipelines-pr.yml`
4. Save as name e.g. `boutique-pr-validate` (do **not** overwrite the Topic 09 pipeline)
5. Run once on a branch or wait for a PR

**OIDC / Azure service connection:** **not required** for this pipeline (no Azure tasks).

### Expected output

- Pipeline appears in ADO list alongside the supply-chain pipeline
- Manual run or PR run shows stage **PR validate** with three jobs

### Validation

- [ ] YAML path is `pipelines/azure-pipelines-pr.yml`
- [ ] First run: PreCommit, TerraformValidate, KyvernoTest all green (or failures are real repo issues)

**Deferred validation (needs live ADO + GitHub PR):**

- [ ] Open a PR that touches `policies/` or `terraform/` and confirm the pipeline is queued automatically
- [ ] Open a PR that only changes `README.md` and confirm path filters **skip** the pipeline (optional check)

---

## Step 14.4: Optional branch policy — **Apply later**

### Goal

Require `boutique-pr-validate` to succeed before merge to `main`.

### Why this step is required

Without a required check, the pipeline is advisory only.

### GUI

1. Azure DevOps → **Project settings** → **Repositories** → select the GitHub repo mirror / **Repos** (UI varies with GitHub + ADO integration)
   **or** GitHub → **Settings** → **Branches** → rule on `main` → require status check from the ADO GitHub App check name
2. Add required status: the PR validate pipeline build

Exact UI depends on whether status is published via the Azure Pipelines GitHub App.

### Validation

- [ ] Merge to `main` blocked while PR validate is failing or pending
- [ ] Green PR validate allows merge (subject to your other rules)

---

## Step 14.5: Operator notes

### What this gate does **not** do

| Not in PR CI | Where it lives |
|--------------|----------------|
| Mirror / Trivy / cosign | `azure-pipelines.yml` on `main` (Topic 09) |
| Digest promotion | `azure-pipelines-promote.yml` (Topic 12) |
| Checkov / tfsec | Topic 16 / Package 4 — **scaffolded** (`make checkov`) |
| Live cluster smokes | `tests/integration/*` (manual / post-deploy) |

### Path filters

PRs that only change docs outside the `paths.include` list will **not** trigger this pipeline. That is intentional to save minutes. Broaden `pipelines/azure-pipelines-pr.yml` `pr.paths.include` if you want docs-only PRs gated too.

### Pins

| Variable | Source |
|----------|--------|
| `terraformVersion` | `pipelines/templates/pr-variables.yml` ↔ `versions.yaml` `ci.terraform` |
| `kyvernoCliVersion` | ↔ `versions.yaml` `ci.kyverno_cli` / cluster `gitops.kyverno` |
| `pythonVersion` | ↔ `versions.yaml` `ci.python` |

Keep these three files aligned when bumping tools.

---

## Rollback

1. Remove or disable the ADO PR pipeline (or clear branch policy)
2. Leave YAML in Git — disabling ADO registration is enough to stop gates
3. Do **not** set `pr:` on `azure-pipelines.yml` as a substitute (would pull OIDC/ACR into PR builds)

---

## End-to-end validation checklist

### Scaffold (no Azure)

- [x] Files listed in Step “Before you begin” exist
- [ ] `./tests/ci/pr-validate.sh` exits 0 locally

### Apply later (ADO live)

- [ ] Pipeline registered from `pipelines/azure-pipelines-pr.yml`
- [ ] Sample PR runs three jobs green
- [ ] Optional: required status on `main`

---

## Related docs

| Doc | Role |
|-----|------|
| [09-ci-pipeline.md](09-ci-pipeline.md) | Supply-chain on `main` |
| [pipelines/README.md](../../pipelines/README.md) | Pipeline index |
| [tests/README.md](../../tests/README.md) | TEST IDs / CI matrix |
| [docs/troubleshooting/pipeline-failures.md](../troubleshooting/pipeline-failures.md) | ADO failure patterns |
| [16-iac-scanning.md](16-iac-scanning.md) | Next: Checkov on PRs (Package 4) — may not exist until scaffolded |
