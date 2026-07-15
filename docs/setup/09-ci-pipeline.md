# 09 — CI Pipeline (Mirror, Scan, Sign)

**Audience:** L2 — Implementer
**Estimated time:** 180 minutes
**Prerequisites:** [04-ado-oidc.md](04-ado-oidc.md) ✅ · [03-cluster-resources.md](03-cluster-resources.md) ✅
**Creates:** ADO pipeline, cosign key pair in Key Vault, signed Boutique v0.10.5 images in ACR
**Related ADRs:** [0005](../adr/0005-cosign-key-based-signing.md), [0009](../adr/0009-mirror-upstream-images.md)

---

## Topic goal

When this topic is complete, an **Azure DevOps pipeline** mirrors all **11 Online Boutique v0.10.5** service images from Google Artifact Registry to **ACR**, runs **Trivy** with a **CRITICAL** severity gate, and **cosign-signs** each image **by digest** with `--tlog-upload=false`. The cosign **public key** is pasted into Kyverno policy `02-verify-image-signatures.yaml` so admission can verify signed workloads in Topic 10.

## Why this topic is required

Kyverno enforces ACR allowlist and signature verification at admission time. Images must exist in your ACR and be signed before Boutique deploys. This pipeline is the supply-chain gate between upstream Google images and your cluster.

---

## Before you begin

- [ ] Topic 04 complete: ADO service connection `azure-boutique-oidc` works
- [ ] Topic 03 complete: ACR and Key Vault exist
- [ ] `terraform output` values available for `acr_name`, `key_vault_name`
- [ ] Repository pushed to **GitHub** (Topic 00 Step 4) — pipeline YAML must be in GitHub
- [ ] Optional local tools: `cosign`, `trivy`, `jq`

```bash
cd terraform/environments/dev
terraform output -raw acr_name
terraform output -raw key_vault_name
terraform output -raw acr_login_server
```

---

## Step 9.1: Review pipeline layout

### Goal

Understand mirror → scan → sign stages and variable sources.

### Why this step is required

Pipeline variables must match Terraform outputs and ADO service connection name exactly.

### Commands

```bash
cd /path/to/boutique-aks-devsecops
ls -la pipelines/
cat pipelines/azure-pipelines.yml
cat pipelines/templates/variables.yml
cat versions.yaml | grep -A30 "supply_chain:"
```

### Expected output

| File | Purpose |
|------|---------|
| `pipelines/azure-pipelines.yml` | Main pipeline (Validate + MirrorScanSign) |
| `pipelines/templates/variables.yml` | Pinned versions, ACR/KV names, service list |
| `pipelines/templates/build-scan-sign.yml` | Mirror, Trivy, cosign loop |
| `pipelines/templates/promote-digest.yml` | GitOps digest promotion (Topic 12) |

### Validation

- [ ] `boutiqueVersion` is `v0.10.5`
- [ ] `trivyVersion` is `0.51.4`, `cosignVersion` is `2.2.4`
- [ ] Eleven services listed in `boutiqueServices`

---

## Step 9.2: Generate cosign key pair and store in Key Vault

### Goal

Create a cosign key pair; store private key in Key Vault for the pipeline; retain public key for Kyverno.

### Why this step is required

ADR-0005 mandates key-based signing. The private key never enters Git or ADO variable secrets — the pipeline reads it via OIDC + Key Vault Secrets User RBAC (Topic 04).

### Commands

```bash
cd /path/to/boutique-aks-devsecops
KV_NAME="$(cd terraform/environments/dev && terraform output -raw key_vault_name)"

# Generate key pair (interactive passphrase — use a strong passphrase or empty for lab only)
cosign generate-key-pair

# Store in Key Vault (files created in current directory)
az keyvault secret set \
  --vault-name "${KV_NAME}" \
  --name cosign-private-key \
  --file cosign.key

az keyvault secret set \
  --vault-name "${KV_NAME}" \
  --name cosign-public-key \
  --file cosign.pub

# Secure local copies — do not commit
chmod 600 cosign.key
rm -f cosign.key cosign.pub   # optional after KV upload; keep backup offline if you prefer
```

If cosign is not installed locally:

```bash
COSIGN_VERSION=2.2.4
curl -fsSL -o /usr/local/bin/cosign \
  "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-amd64"
chmod +x /usr/local/bin/cosign
```

### Expected output

```text
Secret saved: cosign-private-key
Secret saved: cosign-public-key
```

### Validation

```bash
az keyvault secret show --vault-name "${KV_NAME}" --name cosign-public-key --query name -o tsv
az keyvault secret show --vault-name "${KV_NAME}" --name cosign-private-key --query name -o tsv
```

- [ ] Both secrets exist in Key Vault

---

## Step 9.3: Update Kyverno signature policy with public key

### Goal

Replace `<COSIGN_PUBLIC_KEY_PEM>` placeholder in Kyverno policy so cluster admission can verify signatures.

### Why this step is required

Topic 08 installed the policy with a placeholder. After this step, only cosign-signed ACR images pass admission (once Boutique deploys in Topic 10).

### Commands

```bash
KV_NAME="$(cd terraform/environments/dev && terraform output -raw key_vault_name)"
PUB_KEY="$(az keyvault secret show --vault-name "${KV_NAME}" --name cosign-public-key --query value -o tsv)"

# Review current placeholder
grep -n "COSIGN_PUBLIC_KEY" policies/kyverno/cluster/02-verify-image-signatures.yaml

# Replace placeholder — use your editor, or:
python3 <<'PY'
import pathlib, subprocess, os
kv = subprocess.check_output(
    ["terraform", "-chdir=terraform/environments/dev", "output", "-raw", "key_vault_name"],
    text=True,
).strip()
pub = subprocess.check_output(
    ["az", "keyvault", "secret", "show", "--vault-name", kv, "--name", "cosign-public-key", "--query", "value", "-o", "tsv"],
    text=True,
)
path = pathlib.Path("policies/kyverno/cluster/02-verify-image-signatures.yaml")
text = path.read_text()
text = text.replace("<COSIGN_PUBLIC_KEY_PEM>", pub.strip())
path.write_text(text)
print("Updated", path)
PY
```

Also replace `<ACR_NAME>` if not done in Topic 08:

```bash
ACR_NAME="$(cd terraform/environments/dev && terraform output -raw acr_name)"
sed -i.bak "s/<ACR_NAME>/${ACR_NAME}/g" policies/kyverno/cluster/00-registry-allowlist.yaml
sed -i.bak "s/<ACR_NAME>/${ACR_NAME}/g" policies/kyverno/cluster/02-verify-image-signatures.yaml
rm -f policies/kyverno/cluster/*.bak
```

Commit and push policy updates; Argo CD `kyverno-policies` app syncs automatically.

### Validation

```bash
grep -c "BEGIN PUBLIC KEY" policies/kyverno/cluster/02-verify-image-signatures.yaml
kubectl get clusterpolicy verify-image-signatures -o yaml 2>/dev/null | grep -c "BEGIN PUBLIC KEY" || echo "Sync pending"
```

- [ ] Policy file contains PEM public key (not placeholder)
- [ ] Git pushed; Argo CD syncs `kyverno-policies`

---

## Step 9.4: Align pipeline variables with Terraform

### Goal

Set `acrName`, `acrLoginServer`, and `keyVaultName` in `pipelines/templates/variables.yml` or ADO pipeline variables.

### Why this step is required

Default placeholders in `variables.yml` must match your Terraform tfvars outputs.

### Commands

```bash
cd terraform/environments/dev
ACR_NAME="$(terraform output -raw acr_name)"
ACR_LOGIN="$(terraform output -raw acr_login_server)"
KV_NAME="$(terraform output -raw key_vault_name)"
echo "acrName: ${ACR_NAME}"
echo "acrLoginServer: ${ACR_LOGIN}"
echo "keyVaultName: ${KV_NAME}"
```

Edit `pipelines/templates/variables.yml` if values differ from defaults, **or** override in ADO: **Pipelines** → your pipeline → **Edit** → **Variables** (pipeline-level overrides).

### Validation

- [ ] `azureServiceConnection` is `azure-boutique-oidc` (matches Topic 04)
- [ ] ACR and KV names match `terraform output`

---

## Step 9.5: Create Azure DevOps pipeline (GUI)

### Goal

Register the pipeline in ADO pointing at `pipelines/azure-pipelines.yml`.

### Why this step is required

ADO must load YAML from your **GitHub** repository and use the OIDC service connection for Azure resources.

### GUI steps

1. Azure DevOps → your project → **Pipelines** → **New pipeline**
2. **GitHub** → authorize Azure Pipelines if prompted → select **`boutique-aks-devsecops`**
3. **Existing Azure Pipelines YAML file** → branch `main` → path `/pipelines/azure-pipelines.yml`
4. **Continue** → review → **Run** (or Save without running)

**Grant pipeline access to GitHub:** When connecting the repo, allow Azure Pipelines to access your GitHub organization/repository. Digest promotion (Topic 12) requires **push** permission to `main` — enable **Grant access permission to all pipelines** on the GitHub service connection, or approve when prompted on first promote run.

On first run, authorize:

- **azure-boutique-oidc** service connection (if prompted)
- **Docker** (agent uses `docker pull` / `docker push`)

### Validation

- [ ] Pipeline appears in ADO with stages **Validate** and **MirrorScanSign**
- [ ] YAML path is `pipelines/azure-pipelines.yml`

---

## Step 9.6: Run pipeline and validate supply chain

### Goal

Execute mirror/scan/sign for all 11 services; confirm signed digests in ACR.

### Why this step is required

This is the end-to-end proof that OIDC, ACR push, Trivy, and cosign work together.

### Commands

Run pipeline from ADO (**Run pipeline** on `main`), or queue from CLI if configured:

```bash
# Optional — requires az devops extension and PAT; GUI run is fine
# az pipelines run --name "boutique-supply-chain" --branch main
```

Monitor ADO logs for each service: pull → push → Trivy → cosign sign → cosign verify.

After success, validate locally:

```bash
ACR_NAME="$(cd terraform/environments/dev && terraform output -raw acr_name)"
ACR_LOGIN="$(cd terraform/environments/dev && terraform output -raw acr_login_server)"
KV_NAME="$(cd terraform/environments/dev && terraform output -raw key_vault_name)"

az acr repository list --name "${ACR_NAME}" -o table

# Example: verify frontend digest signature
DIGEST="$(az acr repository show-manifests \
  --name "${ACR_NAME}" --repository frontend \
  --query "[?contains(tags, 'v0.10.5')].digest | [0]" -o tsv)"
IMAGE="${ACR_LOGIN}/frontend@${DIGEST}"
echo "Checking ${IMAGE}"

az acr login --name "${ACR_NAME}"

az keyvault secret show --vault-name "${KV_NAME}" --name cosign-public-key --query value -o tsv > /tmp/cosign.pub
cosign verify --key /tmp/cosign.pub --insecure-ignore-tlog "${IMAGE}"
rm -f /tmp/cosign.pub
```

### Expected output

- Pipeline stage **MirrorScanSign** green
- Artifact **digest-manifest** published (JSON map of service → digest)
- `cosign verify` succeeds for at least one service
- All 11 repositories listed in ACR

### Validation checklist

```bash
SERVICES="frontend cartservice checkoutservice currencyservice emailservice paymentservice productcatalogservice recommendationservice shippingservice adservice loadgenerator"
for s in ${SERVICES}; do
  az acr repository show-tags --name "${ACR_NAME}" --repository "${s}" --query "[?contains(@, 'v0.10.5')]" -o tsv || echo "MISSING: ${s}"
done | wc -l
# Expect 11 lines with v0.10.5
```

- [ ] Pipeline succeeded
- [ ] 11 images in ACR tagged `v0.10.5`
- [ ] `cosign verify` passes locally
- [ ] `digest-manifest` artifact downloadable from ADO

---

## Step 9.7: (Optional) Enable dev GitOps promotion

### Goal

Uncomment promote stage after Topic 10 creates `gitops/apps/boutique/overlays/dev/`.

### Why this step is required

Not required for Topic 09 completion. Topic 10 may set digests manually first; promotion automation is enabled in Topic 12.

### Commands

In `pipelines/azure-pipelines.yml`, uncomment:

```yaml
  - template: templates/promote-digest.yml
    parameters:
      targetEnvironment: dev
```

Requires `kustomize` on the agent and `persistCredentials: true` for Git push to **GitHub**. See [12-promotion-stage-prod.md](12-promotion-stage-prod.md).

### Validation

- [ ] Skipped until Topic 10 overlay exists (default)

---

## Troubleshooting

| Symptom | Likely cause | Guide |
|---------|--------------|-------|
| `AADSTS700213` / federated credential | SC name mismatch | [ado-oidc.md](../troubleshooting/ado-oidc.md) |
| `denied: requested access denied` on ACR push | Missing AcrPush on pipeline UAMI | Topic 04 RBAC |
| Key Vault access denied | Missing Secrets User on pipeline UAMI | Topic 04 RBAC |
| Trivy CRITICAL findings | Upstream CVE in image | [pipeline-failures.md](../troubleshooting/pipeline-failures.md) |
| cosign sign fails | Wrong key format or passphrase | [pipeline-failures.md](../troubleshooting/pipeline-failures.md) |
| Kyverno blocks unsigned pods | Policy not synced or wrong public key | [image-signature.md](../troubleshooting/image-signature.md) |

Full reference: [docs/troubleshooting/pipeline-failures.md](../troubleshooting/pipeline-failures.md)

---

## Security notes

- Private cosign key: **Key Vault only** — see [supply-chain.md](../security/supply-chain.md)
- Pipeline uses `--tlog-upload=false` (ADR-0005); Kyverno uses `ignoreTlog: true`
- Trivy gate: **CRITICAL only** — HIGH/MEDIUM logged but do not fail the build (lab default)

---

## Topic complete checklist

- [ ] cosign key pair in Key Vault (`cosign-private-key`, `cosign-public-key`)
- [ ] Kyverno `02-verify-image-signatures.yaml` updated with public key and `<ACR_NAME>`
- [ ] ADO pipeline registered and green on `main`
- [ ] 11 Boutique v0.10.5 images in ACR, signed by digest
- [ ] `digest-manifest` artifact published

---

## Next step

**Topic 10 — Boutique dev deploy:** GitOps manifests for dev namespace, image digests from ACR, ingress at `dev-boutique.biroltilki.art`.

Guide: [10-boutique-dev.md](10-boutique-dev.md) (Phase B — pending until you approve Topic 10)

**Phase C protocol:** Confirm each step above with ✅ or paste errors before proceeding to Topic 10.

**Approval phrase for Phase B Topic 10:** `Approved — begin Setup Phase B, Topic 10`
