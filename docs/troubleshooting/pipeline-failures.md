# Pipeline failures — troubleshooting

Symptoms and fixes for the Azure DevOps mirror / scan / sign pipeline ([09-ci-pipeline.md](../setup/09-ci-pipeline.md)).

---

## Quick diagnostics

| Check | Command / location |
|-------|-------------------|
| Service connection | ADO → Project settings → Service connections → `azure-boutique-oidc` |
| Federation subject | `sc://{org}/{project}/azure-boutique-oidc` |
| Pipeline variables | `pipelines/templates/variables.yml` vs `terraform output` |
| UAMI RBAC | AcrPush on ACR; Key Vault Secrets User on KV |
| ADO run logs | Stage **MirrorScanSign** → task **Mirror, Trivy scan, cosign sign** |

---

## Authentication and Azure access

### `AADSTS700213` — No matching federated identity record

**Cause:** ADO service connection name or org/project does not match Terraform federated credential `subject`.

**Fix:**

1. Confirm ADO service connection name is exactly `azure-boutique-oidc` (or update Terraform `ado_service_connection_name` and re-apply).
2. Re-run [verify-oidc-trust.sh](../../scripts/verify-oidc-trust.sh) from Topic 04.
3. See [ado-oidc.md](ado-oidc.md).

### `AuthorizationFailed` on Key Vault

**Cause:** Pipeline UAMI lacks **Key Vault Secrets User** on the vault.

**Fix:**

```bash
cd terraform/environments/dev
terraform apply   # ado-federation module grants KV Secrets User
```

Verify role assignment on the Key Vault scope for `uami-ado-pipeline`.

### `denied: requested access denied` (ACR push)

**Cause:** Missing **AcrPush** on pipeline identity.

**Fix:** Re-apply Topic 04 Terraform; confirm `azurerm_role_assignment` for AcrPush on ACR resource ID.

---

## Docker and mirror

### `docker pull` timeout / TLS error from GAR

**Cause:** Transient network or Google Artifact Registry outage.

**Fix:** Retry pipeline. Confirm agent has outbound HTTPS. Upstream image:

```text
us-central1-docker.pkg.dev/google-samples/microservices-demo/<service>:v0.10.5
```

### `ERROR: Could not resolve digest for <service>`

**Cause:** Push succeeded but manifest query failed, or tag not yet visible.

**Fix:**

```bash
ACR_NAME="<your-acr>"
az acr repository show-manifests --name "${ACR_NAME}" --repository frontend -o table
```

Re-run pipeline after confirming tag `v0.10.5` exists.

### Wrong image count in ACR

**Cause:** Pipeline failed mid-loop; partial success.

**Fix:** Re-run full pipeline (idempotent — re-tags and re-signs). Validate all 11 services:

```bash
# From versions.yaml service list
az acr repository list --name "${ACR_NAME}" -o table
```

---

## Trivy scan failures

### Exit code 1 — CRITICAL vulnerabilities found

**Cause:** Trivy gate: `--severity CRITICAL --exit-code 1`.

**Options (test):**

1. **Preferred for pinned upstream v0.10.5:** Pipeline uses `--ignore-status fixed` — fail only on CRITICAL **unfixed** CVEs (Google has not yet published patched v0.10.5 images). Document accepted CVE IDs below if scan still fails.
2. **Strict mode:** Remove `--ignore-status fixed` from [build-scan-sign.yml](../../pipelines/templates/build-scan-sign.yml) when upstream releases patched images.
3. **Temporary bypass (not recommended):** Add `|| true` after trivy in a forked template — defeats supply-chain gate.
4. **Inspect:** Download ADO log; run locally:

```bash
trivy image --scanners vuln --severity CRITICAL --ignore-status fixed <acr>.azurecr.io/frontend@sha256:...
```

**Known upstream fixed CRITICALs on v0.10.5 (test accepted with `--ignore-status fixed`):**

- `CVE-2026-33186` — `google.golang.org/grpc` (frontend; fix in grpc 1.79.3)
- `CVE-2025-68121` — Go stdlib TLS (multiple services; fix in Go 1.25.7+)

### Trivy binary install fails

**Cause:** Pinned version no longer published on GitHub / `get.trivy.dev` (common for older pins such as `0.51.4`).

**Fix:** Set `trivy` in [versions.yaml](../../versions.yaml) and `trivyVersion` in [variables.yml](../../pipelines/templates/variables.yml) to a tag that exists on [Trivy releases](https://github.com/aquasecurity/trivy/releases) (e.g. `0.72.0`). Re-run pipeline — install uses official `contrib/install.sh`.

---

## cosign sign / verify failures

### `error signing blob: invalid key`

**Cause:** Key Vault secret is not raw cosign private key PEM, or passphrase mismatch.

**Fix:**

1. Regenerate: `cosign generate-key-pair` (note passphrase).
2. Re-upload `cosign.key` to Key Vault secret `cosign-private-key`.
3. If using passphrase, pipeline must pass `--key` with env `COSIGN_PASSWORD` — default template assumes **unencrypted** test key.

### `unknown flag: --tlog-upload` on cosign verify

**Cause:** `--tlog-upload` is a **sign** flag only; verify uses `--insecure-ignore-tlog` for key-based signing (ADR-0005).

**Fix:** In [build-scan-sign.yml](../../pipelines/templates/build-scan-sign.yml):

```bash
cosign verify --key "${PUB_KEY}" --insecure-ignore-tlog "${DEST_DIGEST_REF}"
```

**Cause:** Public key in KV does not match private key used to sign.

**Fix:** Re-upload matching `cosign.pub` to `cosign-public-key`. Update Kyverno policy PEM to match.

### `unknown flag: --tlog-upload`

**Cause:** Wrong cosign version (need 2.2.x).

**Fix:** `cosignVersion: 2.2.4` in `variables.yml`.

---

## Pipeline configuration

### Empty variable errors in Validate stage

**Cause:** Template variables not loaded or ADO override cleared a value.

**Fix:** Check `pipelines/azure-pipelines.yml` includes `templates/variables.yml`. Set pipeline variables in ADO UI for `acrName`, `keyVaultName` if not committed.

### Docker not available on agent

**Cause:** Non-standard pool or container job without Docker socket.

**Fix:** Use `vmImage: ubuntu-22.04` Microsoft-hosted pool (default in template).

---

## Kyverno interaction (post-deploy)

Pipeline success does not guarantee pod admission. If Boutique pods fail with signature errors after Topic 10:

- Confirm `02-verify-image-signatures.yaml` has correct public key and ACR name.
- Confirm deployment uses `@sha256:` digest or tag that resolves to signed manifest.
- See [image-signature.md](image-signature.md) and [kyverno-admission.md](kyverno-admission.md).

---

## Reporting issues

Include: ADO build ID, failing service name, log excerpt (redact keys), `terraform output acr_name`, and validation command output.
