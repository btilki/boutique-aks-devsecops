# 17 — SBOM + Cosign Attestations

**Audience:** L2 — Implementer
**Estimated time:** 60–90 minutes (pipeline re-run) after Topics 08–09
**Prerequisites:** [09-ci-pipeline.md](09-ci-pipeline.md) ✅ · [08-admission-policies.md](08-admission-policies.md) ✅
**Creates:** SPDX JSON SBOM per Boutique image, cosign attestation on digest, Kyverno attestation policy (Audit → Enforce)
**Related ADRs:** [0014](../adr/0014-sbom-cosign-attestations.md), [0005](../adr/0005-cosign-key-based-signing.md), [0009](../adr/0009-mirror-upstream-images.md)
**Mode:** Pipeline + policy files are in Git. Generating attestations and flipping Kyverno to **Enforce** need a live ACR/ADO/cluster (**Apply later**).

---

## Topic goal

When this topic is complete:

1. The supply-chain pipeline generates an **SPDX JSON** SBOM (Trivy) for each of the 11 Boutique services and **`cosign attest`s** it to the image digest.
2. CI runs **`cosign verify-attestation`** (key-based, no Rekor).
3. Kyverno policy `verify-sbom-attestations` is synced (**Audit** first, then **Enforce**).
4. Pipeline artifact `sboms-spdx` holds the SBOM files for audit/download.

## Why this topic is required

Signatures prove *who* pushed a digest; SBOMs describe *what* is inside. Attestations bind the SBOM to the digest so admission (or auditors) can require both integrity and inventory — without rebuilding Boutique from source.

---

## Before you begin

```bash
cd /path/to/boutique-aks-devsecops
grep -n enableSbomAttest pipelines/templates/variables.yml
ls policies/kyverno/cluster/05-verify-sbom-attestation.yaml
grep -n "05-verify-sbom" policies/kyverno/kustomization.yaml
```

**Expected:** `enableSbomAttest: "true"`; policy present and listed in kustomization; `validationFailureAction: Audit`.

---

## Step 17.1: Review design (ADR-0014)

### Goal

Confirm tool choices and predicate type.

| Item | Value |
|------|--------|
| SBOM format | SPDX JSON via `trivy image --format spdx-json` |
| cosign type | `spdxjson` (`cosignAttestType`) |
| Predicate (Kyverno) | `https://spdx.dev/Document` |
| Keys | Same KV pair as Topic 09 (`--tlog-upload=false`) |
| Kyverno start mode | **Audit** |

### Validation

- [ ] You accept Audit-first rollout (Enforce too early blocks pods)

---

## Step 17.2: Confirm pipeline scaffold

### Goal

See SBOM/attest steps inside the mirror loop.

### Commands

```bash
grep -n "SPDX\|attest\|enableSbomAttest\|sboms-spdx" pipelines/templates/build-scan-sign.yml
```

### Expected flow (per service)

```text
pull → push → Trivy CRITICAL → cosign sign → verify
  → Trivy SPDX SBOM → cosign attest → verify-attestation
```

Emergency bypass: set ADO pipeline variable `enableSbomAttest` = `false` (or edit `variables.yml`) and re-run.

### Validation

- [ ] Artifact publish for `sboms-spdx` is conditioned on `enableSbomAttest == true`

---

## Step 17.3: Align Kyverno public key

### Goal

Attestation policy uses the **same** PEM as `02-verify-image-signatures.yaml`.

### Commands

```bash
# Diff public key blocks (should match after Topic 09 live key paste)
diff <(sed -n '/BEGIN PUBLIC KEY/,/END PUBLIC KEY/p' policies/kyverno/cluster/02-verify-image-signatures.yaml) \
     <(sed -n '/BEGIN PUBLIC KEY/,/END PUBLIC KEY/p' policies/kyverno/cluster/05-verify-sbom-attestation.yaml)
```

### Apply later

If keys diverge after a rotation, update **both** policies in one PR, then re-sign **and** re-attest (full Topic 09 pipeline).

---

## Step 17.4: Run supply-chain pipeline — **Apply later**

### Goal

Produce signatures + SPDX attestations in ACR; publish SBOM artifact.

### Commands / GUI

1. Ensure Topics 03–04, 09 Key Vault cosign secrets exist
2. Run ADO pipeline from `pipelines/azure-pipelines.yml` on `main`
3. Download artifact `sboms-spdx` — expect 11 `*.spdx.json` files

### Validation

```bash
# Example for one service after az acr login
cosign verify-attestation --type spdxjson \
  --key cosign.pub --insecure-ignore-tlog \
  <ACR_LOGIN_SERVER>/frontend@sha256:<DIGEST>
```

- [ ] Pipeline green including attest steps
- [ ] `sboms-spdx` artifact present
- [ ] Spot-check `verify-attestation` for `frontend`

---

## Step 17.5: Sync Kyverno Audit, then Enforce — **Apply later**

### Goal

Observe attestation gaps without blocking, then enforce.

### Commands

```bash
# After Argo sync of policies
kubectl get clusterpolicy verify-sbom-attestations -o jsonpath='{.spec.validationFailureAction}{"\n"}'
# Expected initially: Audit

# Watch policy reports / Kyverno logs for warn events while Boutique runs
```

When Audit is clean (no missing-attestation warnings on Boutique pods):

1. Edit `policies/kyverno/cluster/05-verify-sbom-attestation.yaml` → `validationFailureAction: Enforce`
2. Commit, sync Argo
3. Rollout restart Boutique deployments if needed

### Validation

- [ ] Audit: Boutique healthy; optional warnings investigated
- [ ] Enforce: unsigned/unattested ACR image probe is **denied**; signed+attested digests **admit**

---

## Step 17.6: Operator notes

| Topic | Note |
|-------|------|
| redis / busybox | Not in `boutiqueServices` loop — still signed manually in Topic 10; SBOM attest optional stretch |
| Re-mirror after teardown | ACR wipe destroys attestations — re-run full pipeline |
| Trivy version drift | Doc used to say 0.51.4; pin is `versions.yaml` / `trivyVersion` (**0.72.0**) |
| Vuln attestations | Not this topic — Trivy CRITICAL remains the gate; vuln predicate attestations are a future stretch |

---

## Rollback

1. Set `enableSbomAttest: "false"` and re-run pipeline (sign-only)
2. Remove `05-verify-sbom-attestation.yaml` from `policies/kyverno/kustomization.yaml` or set Audit
3. Do **not** delete cosign signatures when rolling back attestations only

---

## End-to-end validation checklist

### Scaffold (no Azure)

- [x] ADR-0014 + Topic 17
- [x] Pipeline SBOM/attest + variables
- [x] Kyverno `05-verify-sbom-attestation.yaml` (Audit) in kustomization
- [ ] Public key blocks match between policies 02 and 05 (after your Topic 09 key)

### Apply later

- [ ] Pipeline produces attestations + `sboms-spdx` artifact
- [ ] `cosign verify-attestation` OK for sample services
- [ ] Kyverno Enforce without breaking Boutique

---

## Related docs

| Doc | Role |
|-----|------|
| [09-ci-pipeline.md](09-ci-pipeline.md) | Mirror / sign foundation |
| [docs/security/supply-chain.md](../security/supply-chain.md) | Supply-chain overview |
| [image-signature.md](../troubleshooting/image-signature.md) | Signature troubleshooting |
| [pipeline-failures.md](../troubleshooting/pipeline-failures.md) | ADO failures |
