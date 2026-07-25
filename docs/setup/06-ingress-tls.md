# 06 — Ingress + TLS

**Audience:** L2 — Implementer
**Estimated time:** 120 minutes (certificate issuance may add 5–15 min)
**Prerequisites:** [05-gitops-bootstrap.md](05-gitops-bootstrap.md) ✅ complete · [02-azure-foundation.md](02-azure-foundation.md) DNS delegated
**Creates:** NGINX Ingress, cert-manager, Let's Encrypt ClusterIssuer (DNS-01), Argo CD HTTPS ingress
**Related ADRs:** — (implements [06-network-design.md](../architecture/06-network-design.md))

---

## Topic goal

When this topic is complete, a **public Azure Load Balancer** fronts **NGINX Ingress**, **cert-manager** issues certificates via **Let's Encrypt DNS-01** against Azure DNS, and **Argo CD** is reachable at `https://argocd-boutique.biroltilki.art` with a valid certificate.

## Why this topic is required

All platform and Boutique hostnames share one ingress IP. TLS automation via DNS-01 avoids HTTP-01 challenges and works behind firewalls. cert-manager + Azure DNS + platform Workload Identity is the locked pattern for this project.

---

## Before you begin

- [ ] Topic 05: Argo CD running; `platform-root` syncs successfully
- [ ] Topic 02: DNS delegation for `biroltilki.art` propagated
- [ ] Topic 03: `terraform output platform_identity_client_id` available
- [ ] Git changes pushed — platform manifests use multi-source `$values` ref

```bash
dig NS biroltilki.art +short
cd terraform/environments/dev
terraform output -raw platform_identity_client_id
terraform output -raw resource_group_name
az account show --query id -o tsv
```

---

## Step 6.1: Patch placeholders in GitOps manifests

### Goal

Replace Topic 06 placeholders with your environment values.

### Why this step is required

ClusterIssuer and cert-manager Workload Identity fail with placeholder values.

### Commands

Edit and commit:

**`gitops/platform/cert-manager/values.yaml`**

```yaml
serviceAccount:
  annotations:
    azure.workload.identity/client-id: "<PLATFORM_IDENTITY_CLIENT_ID>"
```

**`gitops/platform/cert-manager/cluster-issuer-letsencrypt.yaml`**

| Placeholder | Value source |
|-------------|--------------|
| `<ACME_EMAIL>` | Your email for Let's Encrypt |
| `<AZURE_SUBSCRIPTION_ID>` | `az account show --query id -o tsv` |
| `<PLATFORM_IDENTITY_CLIENT_ID>` | `terraform output -raw platform_identity_client_id` |

Confirm `resourceGroupName: rg-boutique-dev-gwc` and `hostedZoneName: biroltilki.art` match your tfvars.

Ensure `ingress-nginx/Application.yaml` and `cert-manager/Application.yaml` use your real GitHub `repoURL` (same as Topic 05).

Push to `main` (or your `targetRevision` branch).

### Validation

- [ ] No `<ACME_EMAIL>` or `<PLATFORM_IDENTITY_CLIENT_ID>` literals remain
- [ ] Changes pushed to Git remote Argo CD reads

---

## Step 6.2: Configure Workload Identity for cert-manager

### Goal

Allow cert-manager pods to authenticate as the platform UAMI for Azure DNS TXT records.

### Why this step is required

DNS-01 solver uses `managedIdentity.clientID` — the pod must exchange Kubernetes SA token for Azure token via federated credential.

### Commands

```bash
cd terraform/environments/dev
RG=$(terraform output -raw resource_group_name)
CLIENT_ID=$(terraform output -raw platform_identity_client_id)
ISSUER=$(terraform output -raw aks_oidc_issuer_url)
IDENTITY_NAME="uami-boutique-platform"

az identity federated-credential create \
  --name cert-manager-dns01 \
  --identity-name "${IDENTITY_NAME}" \
  --resource-group "${RG}" \
  --issuer "${ISSUER}" \
  --subject "system:serviceaccount:cert-manager:cert-manager" \
  --audience "api://AzureADTokenExchange"
```

If credential already exists, update or skip.

### Expected output

```json
{
  "name": "cert-manager-dns01",
  "issuer": "https://...",
  "subject": "system:serviceaccount:cert-manager:cert-manager"
}
```

### Validation

```bash
az identity federated-credential list \
  --identity-name "${IDENTITY_NAME}" \
  --resource-group "${RG}" -o table
```

- [ ] `cert-manager-dns01` credential listed

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `Issuer invalid` | Wrong OIDC URL | Re-copy `aks_oidc_issuer_url` from Topic 03 |
| Identity not found | Name/RG mismatch | `az identity list -g "${RG}" -o table` |

---

## Step 6.3: Sync platform-root application

### Goal

Deploy ingress-nginx, cert-manager, ClusterIssuer, and Argo CD Ingress via GitOps.

### Why this step is required

Topic 06 resources are delivered through `gitops/platform/` synced by `platform-root`.

### Commands

```bash
argocd app sync platform-root
argocd app wait platform-root --health --timeout 600
argocd app list | grep -E 'ingress|cert-manager|platform'
```

Or trigger sync from Argo CD UI on `platform-root`.

### Expected output

New Applications appear (managed by platform kustomization):

| Application | Namespace | Health |
|-------------|-----------|--------|
| ingress-nginx | ingress-nginx | Healthy |
| cert-manager | cert-manager | Healthy |

### Validation

```bash
kubectl get pods -n ingress-nginx
kubectl get pods -n cert-manager
kubectl get clusterissuer letsencrypt-prod
```

- [ ] NGINX controller pod Running
- [ ] cert-manager, webhook, cainjector Running
- [ ] ClusterIssuer `letsencrypt-prod` exists

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `$values` resolution failed | Multi-source misconfigured | Verify `ref: values` repo URL matches Git remote |
| Sync wave ordering | CRDs not ready | Re-sync `cert-manager` app; wait for CRDs |

---

## Step 6.4: Obtain ingress public IP

### Goal

Read the Azure Load Balancer IP for DNS A records.

### Why this step is required

Public hostnames must point to the ingress Service external IP.

### Commands

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'; echo
```

Wait if `<pending>`:

```bash
kubectl get svc -n ingress-nginx -w
```

### Expected output

IPv4 address, e.g. `20.x.x.x`

### Validation

- [ ] External IP assigned (not pending after ~5 min)

---

## Step 6.5: Create DNS A record for Argo CD

### Goal

Point `argocd-boutique.biroltilki.art` to the ingress IP.

### Why this step is required

Let's Encrypt DNS-01 validates zone control; users need resolvable hostname.

### Commands

```bash
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
ZONE_RG=$(cd terraform/environments/dev && terraform output -raw resource_group_name)

az network dns record-set a add-record \
  --resource-group "${ZONE_RG}" \
  --zone-name biroltilki.art \
  --record-set-name argocd-boutique \
  --ipv4-address "${INGRESS_IP}"
```

### GUI instructions (alternative)

1. **Azure Portal** → **DNS zones** → **biroltilki.art** → **+ Record set**
2. Name: `argocd-boutique` → Type: **A** → IP: ingress IP → **OK**

### Validation

```bash
dig +short argocd-boutique.biroltilki.art
```

- [ ] Returns ingress IP

---

## Step 6.6: Wait for TLS certificate Ready

### Goal

Confirm cert-manager completes DNS-01 challenge and issues `argocd-server-tls`.

### Why this step is required

Proves end-to-end DNS, WI, and issuer configuration.

### Commands

```bash
kubectl get certificate -n argocd
kubectl describe certificate argocd-server-tls -n argocd
kubectl get challengerecord -A 2>/dev/null || kubectl get challenges.acme.cert-manager.io -A
```

### Expected output

```text
NAME                READY   SECRET
argocd-server-tls   True    argocd-server-tls
```

May take **5–15 minutes** on first issuance.

### Validation

```bash
kubectl get secret argocd-server-tls -n argocd
```

- [ ] Certificate `READY=True`
- [ ] TLS secret exists

### Common problems

See [cert-manager-dns01.md](../troubleshooting/cert-manager-dns01.md).

---

## Step 6.7: Verify HTTPS access to Argo CD

### Goal

Open Argo CD UI over public HTTPS.

### Why this step is required

Confirms ingress + TLS + Argo CD server integration.

### Commands

```bash
curl -sI "https://argocd-boutique.biroltilki.art" | head -10
```

### Expected output

```text
HTTP/2 200
```

(or `302` redirect — acceptable)

### Validation

- [ ] Browser opens `https://argocd-boutique.biroltilki.art`
- [ ] Certificate issued by Let's Encrypt (no browser warning)
- [ ] Argo CD login page loads

Stop using port-forward for daily access (optional for break-glass).

---

## Topic validation (end-to-end)

```bash
kubectl get pods -n ingress-nginx,cert-manager
kubectl get clusterissuer letsencrypt-prod
kubectl get certificate -n argocd
dig +short argocd-boutique.biroltilki.art
curl -sI "https://argocd-boutique.biroltilki.art" | head -5
```

**Success criteria:**

- [ ] Ingress LB IP assigned
- [ ] DNS A record resolves
- [ ] Certificate Ready
- [ ] HTTPS Argo CD UI works
- [ ] `ingress-nginx` and `cert-manager` Applications Healthy

Update [Setup Index](README.md) Topic 06 to ✅ when complete.

---

## Topic troubleshooting

- [cert-manager-dns01.md](../troubleshooting/cert-manager-dns01.md)
- [argocd-sync.md](../troubleshooting/argocd-sync.md)

---

## Next step

➡️ Continue to **[07-secrets-csi.md](07-secrets-csi.md)** (Topic 07) for Key Vault CSI driver.

Future hostnames (`grafana-boutique`, `dev-boutique`, etc.) reuse the same ingress IP with additional A records (Topics 10–11).
