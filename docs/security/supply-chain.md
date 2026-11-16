# Supply chain security

How this project secures container images from upstream mirror through cluster admission.

**Related:** [ADR-0005](../adr/0005-cosign-key-based-signing.md), [ADR-0009](../adr/0009-mirror-upstream-images.md), [ADR-0014](../adr/0014-sbom-cosign-attestations.md), [07-security-architecture.md](../architecture/07-security-architecture.md), [reference-claims.md](../reference-claims.md)

---

## Lived vs optional

| Path | What it covers |
|------|----------------|
| **Lived (Topics 00–13)** | Mirror → Trivy CRITICAL → cosign sign by digest → Kyverno signature verify |
| **Optional (Topic 17)** | Trivy SPDX SBOM + cosign attest + `verify-attestation`; Kyverno SBOM policy (Audit → Enforce) |

Closed reference proof is the lived path only. SBOM/attest YAML exists in Git; pipeline default keeps it **off** until you apply Topic 17 (`enableSbomAttest`).

---

## Scope

| Layer | Control | Implementation | Path |
|-------|---------|----------------|------|
| Source | Pinned upstream version | Online Boutique v0.10.5 from Google Artifact Registry | Lived |
| Registry | Private ACR | Mirror pipeline; Kyverno ACR allowlist | Lived |
| Build integrity | Not applicable | Images mirrored, not rebuilt in-repo | Lived |
| Vulnerability gate | Trivy CRITICAL | ADO pipeline fails on CRITICAL CVEs | Lived |
| Integrity / authenticity | cosign 2.2.4 | Sign by digest; `--tlog-upload=false` | Lived |
| Runtime enforcement | Kyverno 1.12 | `verifyImages` (signatures), deny `:latest`, pod security baseline | Lived |
| SBOM | Trivy SPDX JSON | Per-service SBOM; artifact `sboms-spdx` when enabled | Optional (Topic 17) |
| SBOM attestation | cosign attest `spdxjson` | Same key; verify-attestation in CI | Optional (Topic 17) |

---

## Mirror pipeline flow (lived)

```mermaid
flowchart LR
    GAR[Google Artifact Registry v0.10.5] --> Pull[docker pull]
    Pull --> Push[ACR push :v0.10.5]
    Push --> Trivy[Trivy CRITICAL gate]
    Trivy --> Sign[cosign sign @digest]
    Sign --> Verify[cosign verify]
    Verify --> KV[Public key in Kyverno]
    KV --> Kyverno[Kyverno admission]
```

**Optional after Topic 17** (when `enableSbomAttest=true`): after sign, also Trivy SPDX SBOM → cosign attest → verify-attestation. Diagram and steps: [17-sbom-attestations.md](../setup/17-sbom-attestations.md).

**Pipeline files:** `pipelines/azure-pipelines.yml`, `pipelines/templates/build-scan-sign.yml`
**Toggle:** `enableSbomAttest` in `pipelines/templates/variables.yml` (default `"false"`; set `"true"` for Topic 17). Keep in sync with `versions.yaml` `supply_chain.enable_sbom_attest`.

**Authentication:** Azure DevOps OIDC → UAMI `uami-ado-pipeline` → AcrPush + Key Vault Secrets User (no long-lived CI secrets).

---

## Image inventory

Eleven services from [versions.yaml](../../versions.yaml):

`frontend`, `cartservice`, `checkoutservice`, `currencyservice`, `emailservice`, `paymentservice`, `productcatalogservice`, `recommendationservice`, `shippingservice`, `adservice`, `loadgenerator`

**Upstream:** `us-central1-docker.pkg.dev/google-samples/microservices-demo/<service>:v0.10.5`
**Destination:** `<acr>.azurecr.io/<service>:v0.10.5` (signed at manifest digest)

---

## cosign key management

| Secret | Location | Used by |
|--------|----------|---------|
| `cosign-private-key` | Azure Key Vault | ADO pipeline (sign; attest when enabled) |
| `cosign-public-key` | Azure Key Vault + Git (Kyverno policy) | Pipeline verify + Kyverno `verifyImages` |

**Generation (Topic 09):**

```bash
cosign generate-key-pair
az keyvault secret set --vault-name <KV> --name cosign-private-key --file cosign.key
az keyvault secret set --vault-name <KV> --name cosign-public-key --file cosign.pub
```

**Signing command (pipeline):**

```bash
cosign sign --key cosign.key --tlog-upload=false -y <acr>.azurecr.io/<service>@sha256:<digest>
```

**Verification (Kyverno):** `policies/kyverno/cluster/02-verify-image-signatures.yaml` with `ignoreTlog: true`, `ignoreSCT: true` (key-based, no Rekor).

### Key rotation

1. Generate new key pair; update Key Vault secrets.
2. Update Kyverno policy public key; sync Argo CD.
3. Re-run mirror pipeline to re-sign all images.
4. Roll workloads to new digests if needed.

---

## Trivy policy

| Setting | Value |
|---------|-------|
| Version | 0.72.0 (see `versions.yaml` / pipeline `trivyVersion`) |
| Severity gate | CRITICAL |
| Exit code | 1 on findings |
| Scan target | ACR image `@digest` after push |
| SBOM | `--format spdx-json` only when `enableSbomAttest=true` (Topic 17) |

HIGH/MEDIUM findings are visible in logs but do not fail the test pipeline. Tighten for production references as needed.

---

## GitOps promotion

Signed digests are promoted to environment overlays via Git (immutable references):

| Environment | Mechanism | Template |
|-------------|-----------|----------|
| dev | Auto-sync after digest commit (Topic 10+) | `promote-digest.yml` (optional) |
| stage / prod | Manual Argo sync + ADO approval for prod | Topic 12 |

Artifact `digest-manifest.json` maps service name → `sha256:...` from each pipeline run.

---

## Threat considerations

| Threat | Mitigation |
|--------|------------|
| Unsigned image deploy | Kyverno `verifyImages` + ACR allowlist |
| `:latest` drift | Kyverno deny-latest-tag policy |
| Compromised CI secret | OIDC federation; cosign private key in KV only |
| Upstream registry swap | Fixed upstream path and tag in pipeline variables |
| CVE in base image | Trivy CRITICAL gate; monitor upstream releases |
| Missing component inventory | Optional SPDX SBOM + cosign attest (Topic 17 / ADR-0014); Kyverno Audit→Enforce after attestations exist |

**Residual risk:** Mirrored images trust Google's build; this project does not rebuild from source. Compromise of cosign private key allows signing (and attesting, when enabled) malicious images until rotation.

---

## Operator checklist

- [ ] Pipeline green on `main` with all 11 services signed (lived path)
- [ ] Kyverno signature policy contains live cosign public key (not placeholder)
- [ ] Topic 17 only: `enableSbomAttest=true`; attestation policy key matches; Enforce only after attestations exist
- [ ] No cosign private key in Git, ADO variables, or logs
- [ ] ACR retention: teardown destroys images — re-run pipeline after rebuild ([13-teardown.md](../setup/13-teardown.md))

**Setup:** [09-ci-pipeline.md](../setup/09-ci-pipeline.md) · [17-sbom-attestations.md](../setup/17-sbom-attestations.md)
**Troubleshooting:** [pipeline-failures.md](../troubleshooting/pipeline-failures.md), [image-signature.md](../troubleshooting/image-signature.md)
