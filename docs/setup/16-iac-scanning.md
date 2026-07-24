# 16 — IaC Scanning (Checkov)

**Audience:** L2 — Implementer
**Estimated time:** 30–45 minutes (local) · ADO already covered by Topic 14 registration
**Prerequisites:** [14-pr-ci.md](14-pr-ci.md) scaffold ✅ · Terraform tree under `terraform/`
**Creates:** Checkov baseline config, local/CI gate on `terraform/`, documented skip list for pilot tradeoffs
**Related:** [phase15-plus.md](../implementation/phase15-plus.md) · [tests/terraform/.checkov.yaml](../../tests/terraform/.checkov.yaml) · [ARCHITECTURE.md](../../ARCHITECTURE.md) Limitations
**Mode:** Runnable locally today. ADO job runs once Topic 14 pipeline is registered (**Apply later** for live PR status).

---

## Topic goal

When this topic is complete, every PR (and `make pr-validate`) runs **Checkov** against `terraform/` and **fails on new findings**. Known production-pilot tradeoffs are explicitly skipped in `.checkov.yaml` with rationale — not silently ignored.

## Why this topic is required

`terraform validate` only checks syntax/schema. Checkov catches misconfigurations (public ACR, missing purge protection, open API server, etc.) before merge. Without a baseline skip list, the pilot design would fail CI on every intentional cost/scope choice.

---

## Before you begin

```bash
cd /path/to/boutique-aks-devsecops
ls tests/terraform/.checkov.yaml tests/terraform/checkov.sh
grep -n checkov versions.yaml pipelines/templates/pr-variables.yml
```

**Expected:** config + script exist; `ci.checkov` / `checkovVersion` pinned to **3.2.510**.

Install locally if needed:

```bash
pip install "checkov==3.2.510"   # versions.yaml ci.checkov
```

---

## Step 16.1: Review baseline skips

### Goal

Understand which CKV_AZURE_* IDs are accepted residuals vs future hardening.

### Why this step is required

Removing a skip without fixing Terraform will break CI; adding skips without comments hides risk.

### Commands

```bash
cat tests/terraform/.checkov.yaml
```

### Expected themes

| Area | Examples | Why skipped |
|------|----------|-------------|
| AKS | private cluster, authorized IPs, paid SLA | Cost / pilot Limitations |
| ACR | public network, quarantine | Cosign+Kyverno+Trivy instead; private ACR deferred |
| Key Vault | firewall, purge protection | Topic 19 / cheap teardown |
| NSG HTTP:80 | CKV_AZURE_160 | Ingress redirect / ACME |

### Validation

- [ ] Every `skip-check` entry has a comment
- [ ] Soft-fail is **false** (new findings fail the gate)

---

## Step 16.2: Run Checkov locally

### Goal

Prove the gate is green on the current tree.

### Commands

```bash
make checkov
# or: ./tests/terraform/checkov.sh
```

### Expected output

```text
[checkov] OK
```

Summary includes **Failed checks: 0** (skips applied).

### Validation

- [ ] Exit code 0
- [ ] Introducing a deliberate bad pattern (e.g. enable ACR admin in a branch) fails Checkov unless that check is skipped — see Step 16.4

---

## Step 16.3: Confirm PR pipeline includes Checkov

### Goal

Ensure ADO PR YAML runs the Checkov job (Package 2 + 4).

### Commands

```bash
grep -n Checkov pipelines/templates/pr-validate.yml
grep -n checkovVersion pipelines/templates/pr-variables.yml
```

### Expected

Job `Checkov` installs `checkov==$(checkovVersion)` and runs `./tests/terraform/checkov.sh`.

### Apply later

After Topic 14 pipeline registration, open a PR touching `terraform/` and confirm the **Checkov IaC scan** job is green.

---

## Step 16.4: How to tighten or fix findings

### When Terraform improves

1. Implement the control in the module
2. **Remove** the corresponding ID from `skip-check`
3. Run `make checkov` — must stay green

### When adding a new skip (exception process)

1. Confirm it matches ARCHITECTURE / ADR / Topic scope (not laziness)
2. Add ID + comment in `.checkov.yaml`
3. Mention in PR description and optionally CHANGELOG

### Deliberate fail test (optional)

Temporarily remove one skip (e.g. `CKV_AZURE_115`), run `make checkov`, expect non-zero exit; restore skip.

---

## Rollback

- Remove Checkov job from `pr-validate.yml` and drop `./tests/terraform/checkov.sh` from `pr-validate.sh` / Makefile
- Or set `soft-fail: true` temporarily (not recommended for merge gates)

---

## End-to-end validation checklist

### Scaffold / local

- [x] `.checkov.yaml` + `checkov.sh` present
- [x] PR template job added
- [ ] `make checkov` exits 0 on your machine
- [ ] `make pr-validate` includes Checkov step

### Apply later (ADO)

- [ ] PR pipeline Checkov job green on a terraform-touching PR

---

## Related docs

| Doc | Role |
|-----|------|
| [14-pr-ci.md](14-pr-ci.md) | PR pipeline registration |
| [19-namespace-hardening.md](19-namespace-hardening.md) | May close KV ACL skips (Package 7) |
| [tests/README.md](../../tests/README.md) | TEST IDs |
| [pipelines/README.md](../../pipelines/README.md) | Pipeline index |
