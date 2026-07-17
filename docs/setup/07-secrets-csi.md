# 07 — Secrets Store CSI

**Audience:** L2 — Implementer
**Estimated time:** 75 minutes
**Prerequisites:** [03-cluster-resources.md](03-cluster-resources.md) ✅ · [05-gitops-bootstrap.md](05-gitops-bootstrap.md) ✅ · [06-ingress-tls.md](06-ingress-tls.md) recommended
**Creates:** CSI driver 1.4.0, Azure provider 1.5.0, test SecretProviderClass + pod in `csi-test`
**Related ADRs:** — (see [07-security-architecture.md](../architecture/07-security-architecture.md))

---

## Topic goal

When this topic is complete, the **Secrets Store CSI driver** and **Azure Key Vault provider** run in `kube-system`, and a **test pod** mounts a Key Vault secret at `/mnt/secrets` using **Workload Identity** (platform UAMI). This proves the secret delivery path for cosign keys (Topic 09) and Grafana (Topic 11).

## Why this topic is required

Application and platform secrets must not live in Git. Key Vault is the system of record; CSI mounts secrets at runtime with least privilege. Validating with an isolated test pod catches WI misconfiguration before production secrets depend on it.

---

## Before you begin

- [ ] Key Vault exists (Topic 03): `terraform output key_vault_name`
- [ ] Platform UAMI exists: `terraform output platform_identity_client_id`
- [ ] Platform UAMI has **Key Vault Secrets User** on the vault (Topic 03 identities module)
- [ ] Argo CD `platform-root` syncing

```bash
cd terraform/environments/dev
terraform output key_vault_name
terraform output -raw platform_identity_client_id
terraform output -raw aks_oidc_issuer_url
az account show --query tenantId -o tsv
```

---

## Step 7.1: Patch CSI manifest placeholders

### Goal

Configure Key Vault and identity values in GitOps test manifests.

### Why this step is required

SecretProviderClass and ServiceAccount need real client ID, vault name, and tenant ID.

### Commands

Edit and commit:

**`gitops/platform/secrets-store-csi/secretproviderclass-example.yaml`** and **`test-serviceaccount.yaml`:**

| Placeholder | Source |
|-------------|--------|
| `<KEY_VAULT_NAME>` | `terraform output -raw key_vault_name` |
| `<TENANT_ID>` | `az account show --query tenantId -o tsv` |
| `<PLATFORM_IDENTITY_CLIENT_ID>` | `terraform output -raw platform_identity_client_id` |

Update `secrets-store-csi/Application.yaml` GitHub `repoURL` if not done in prior topics.

Push to Git.

### Validation

- [ ] No angle-bracket placeholders remain in CSI test manifests

---

## Step 7.2: Create test secret in Key Vault

### Goal

Add `csi-test-secret` for the validation mount.

### Why this step is required

SecretProviderClass references a specific object name that must exist.

### Commands

```bash
KV_NAME=$(cd terraform/environments/dev && terraform output -raw key_vault_name)
az keyvault secret set \
  --vault-name "${KV_NAME}" \
  --name csi-test-secret \
  --value "boutique-csi-test-$(date +%s)"
```

### Expected output

JSON with `"name": "csi-test-secret"` and version ID.

### Validation

```bash
az keyvault secret show --vault-name "${KV_NAME}" --name csi-test-secret --query name -o tsv
```

- [ ] Secret exists

### Security notes

- Test secret is non-production; delete after validation if desired
- Never commit secret values to Git

---

## Step 7.3: Federated credential for test ServiceAccount

### Goal

Allow `csi-test-sa` pods to authenticate as the platform UAMI.

### Why this step is required

Workload Identity requires a federated credential per Kubernetes service account subject.

### Commands

```bash
cd terraform/environments/dev
RG=$(terraform output -raw resource_group_name)
ISSUER=$(terraform output -raw aks_oidc_issuer_url)

az identity federated-credential create \
  --name csi-test-sa \
  --identity-name uami-boutique-platform \
  --resource-group "${RG}" \
  --issuer "${ISSUER}" \
  --subject "system:serviceaccount:csi-test:csi-test-sa" \
  --audience "api://AzureADTokenExchange"
```

### Validation

```bash
az identity federated-credential list \
  --identity-name uami-boutique-platform \
  --resource-group "${RG}" \
  --query "[?name=='csi-test-sa'].subject" -o tsv
```

- [ ] Subject is `system:serviceaccount:csi-test:csi-test-sa`

---

## Step 7.4: Sync platform-root

### Goal

Deploy CSI driver, Azure provider, and test manifests.

### Why this step is required

All Topic 07 resources are delivered via `gitops/platform/`.

### Commands

```bash
argocd app sync platform-root
argocd app sync secrets-store-csi
argocd app wait secrets-store-csi --health --timeout 300
kubectl get pods -n kube-system -l app=secrets-store-csi-driver
kubectl get pods -n kube-system -l app=csi-secrets-store-provider-azure
```

### Expected output

CSI driver and Azure provider pods **Running** in `kube-system`.

### Validation

```bash
kubectl get crd secretproviderclasses.secrets-store.csi.x-k8s.io
kubectl get application secrets-store-csi -n argocd
```

- [ ] CRD exists
- [ ] `secrets-store-csi` Application Healthy

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Provider pod crash | Driver not ready | Wait; re-sync Application |
| Helm version not found | Chart version typo | Confirm 1.4.0 / 1.5.0 in Application.yaml |

---

## Step 7.5: Verify test pod and secret mount

### Goal

Confirm the test pod mounts Key Vault secret content.

### Why this step is required

End-to-end proof of CSI + WI + Key Vault RBAC.

### Commands

```bash
kubectl get pods -n csi-test
kubectl wait --for=condition=Ready pod/csi-test-pod -n csi-test --timeout=180s
kubectl logs -n csi-test csi-test-pod
kubectl exec -n csi-test csi-test-pod -- cat /mnt/secrets/csi-test-secret
```

### Expected output

- Logs show file listing under `/mnt/secrets/`
- `cat` prints the secret value you set in Step 7.2
- Kubernetes Secret `csi-test-kv-secret` created (syncSecret enabled)

```bash
kubectl get secret csi-test-kv-secret -n csi-test
```

### Validation

- [ ] Pod status `Running` (or `Completed` after sleep ends — should be Running during test)
- [ ] Secret file readable inside pod
- [ ] No `FailedMount` events: `kubectl describe pod csi-test-pod -n csi-test`

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `FailedMount` permission denied | KV RBAC or WI | Verify Secrets User role; federated credential |
| `SecretNotFound` | Wrong secret name | Re-run Step 7.2 |
| Pod pending | Image pull / resources | `kubectl describe pod` |

### Recovery

```bash
kubectl delete pod csi-test-pod -n csi-test
argocd app sync platform-root
```

---

## Step 7.6: Document production usage pattern

### Goal

Understand how Topic 09/11 will reuse this pattern.

### Why this step is required

Test resources are test-only; production secrets use the same WI + SecretProviderClass model.

### Reference pattern

| Workload | Namespace | SA annotation | Key Vault secret |
|----------|-----------|---------------|------------------|
| cosign (ADO) | N/A — uses OIDC pipeline identity | ADO UAMI | `cosign-private-key` (Topic 09) |
| Grafana | `monitoring` | platform UAMI | `grafana-admin-password` (Topic 11) |

Remove or disable `csi-test` manifests after validation to avoid non-ACR test images before Kyverno (Topic 08) — or delete test pod after Step 7.5.

---

## Topic validation (end-to-end)

```bash
kubectl get pods -n kube-system | grep -E 'csi|secrets-store'
kubectl get secretproviderclass -n csi-test
kubectl exec -n csi-test csi-test-pod -- test -f /mnt/secrets/csi-test-secret
```

**Success criteria:**

- [ ] CSI driver + Azure provider Running
- [ ] Test pod mounts `csi-test-secret`
- [ ] Optional K8s secret synced via `secretObjects`

Update [Setup Index](README.md) Topic 07 to ✅ when complete.

---

## Topic troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `az login` works but pod fails | WI not federated | Step 7.3 |
| Mount timeout | Provider not registered | Check `csi-secrets-store-provider-azure` pods |
| Wrong vault | Placeholder KV name | Patch SecretProviderClass |

---

## Next step

➡️ Continue to **[08-admission-policies.md](08-admission-policies.md)** (Topic 08) for Kyverno admission policies.

Optional before Topic 08: delete `csi-test-pod` or remove test manifests from `gitops/platform/kustomization.yaml` to avoid `:latest`/non-ACR image policy conflicts.
