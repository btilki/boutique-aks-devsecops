# 15 — NetworkPolicies (Boutique east-west isolation)

**Audience:** L2 — Implementer
**Estimated time:** 60–90 minutes (after cluster supports NetworkPolicy)
**Prerequisites:** [03-cluster-resources.md](03-cluster-resources.md) · [10-boutique-dev.md](10-boutique-dev.md) · [06-ingress-tls.md](06-ingress-tls.md)
**Creates:** Ingress default-deny + Boutique service-graph NetworkPolicies (all overlays); optional AKS `network_policy = "azure"`
**Related:** [phase15-plus.md](../implementation/phase15-plus.md) · [06-network-design.md](../architecture/06-network-design.md) · [base/networkpolicies/README.md](../../gitops/apps/boutique/base/networkpolicies/README.md)
**Mode:** Manifests + Terraform hooks are in Git. Enforcement and negative tests need a live cluster (**Apply later**).

---

## Topic goal

When this topic is complete:

1. Each `boutique-*` namespace has **ingress default-deny** plus allow rules matching Online Boutique v0.10.5 call paths.
2. North-south traffic still works: `ingress-nginx` → `frontend:8080`.
3. AKS enforces NetworkPolicy via **Azure NPM** (`network_policy = "azure"`), set at cluster create when rebuilding.

## Why this topic is required

Without NetworkPolicy, any pod in the cluster (or namespace) that can resolve a Service can speak to Boutique backends. Default-deny + allow-list shrinks east-west blast radius — deferred from Phase 13, now Phase 17 / Package 3.

---

## Before you begin

- [ ] Understand: Azure CNI **without** `network_policy` **does not enforce** these objects
- [ ] Scaffold present:

```bash
cd /path/to/boutique-aks-devsecops
ls gitops/apps/boutique/base/networkpolicies/
grep -n networkpolicies gitops/apps/boutique/base/kustomization.yaml
grep -n network_policy terraform/modules/aks/main.tf terraform/environments/dev/variables.tf
```

**Expected:** `00-default-deny-ingress.yaml`, `10-allow-frontend.yaml`, `20-allow-backends.yaml`, `kustomization.yaml`, `README.md`; base kustomization includes `networkpolicies`; TF variable wired.

---

## Step 15.1: Review the service graph and policies

### Goal

Confirm allow rules match `*_SERVICE_ADDR` / `REDIS_ADDR` in upstream manifests.

### Why this step is required

A missing edge breaks checkout or cart; an extra edge weakens isolation.

### Commands

```bash
cd /path/to/boutique-aks-devsecops
cat gitops/apps/boutique/base/networkpolicies/README.md
# Render (no cluster needed)
kubectl kustomize gitops/apps/boutique/overlays/dev | grep -E 'kind: NetworkPolicy|^  name:'
```

### Expected output

| Policy | Protects | Allows from (summary) |
|--------|----------|------------------------|
| `default-deny-ingress` | all pods | _(none)_ |
| `allow-frontend` | frontend:8080 | ingress-nginx, loadgenerator, monitoring |
| `allow-productcatalogservice` | :3550 | frontend, checkout, recommendation |
| `allow-currencyservice` | :7000 | frontend, checkout |
| `allow-cartservice` | :7070 | frontend, checkout |
| `allow-recommendationservice` | :8080 | frontend |
| `allow-shippingservice` | :50051 | frontend, checkout |
| `allow-checkoutservice` | :5050 | frontend |
| `allow-adservice` | :9555 | frontend |
| `allow-emailservice` | :8080 | checkout |
| `allow-paymentservice` | :50051 | checkout |
| `allow-redis-cart` | :6379 | cartservice |

### Validation

- [ ] `kubectl kustomize` lists **12** NetworkPolicy names (1 deny + 1 frontend + 10 backends)
- [ ] Egress is **not** default-denied (by design in this package)

---

## Step 15.2: Enable Azure Network Policy on AKS — **Apply later**

### Goal

Set `aks_network_policy = "azure"` so policies are enforced.

### Why this step is required

Policies alone are documentation without a plugin.

### Important

Changing `network_policy` on an **existing** AKS cluster often requires **cluster recreate**. Prefer setting this on the **next rebuild** (Topic 03), before or with first Boutique sync.

### Commands

1. In `terraform/environments/dev/terraform.tfvars` (gitignored):

```hcl
aks_network_policy = "azure"
```

(Example already commented in `terraform.tfvars.example`.)

2. Plan / apply (or include in Topic 03 apply on rebuild):

```bash
cd terraform/environments/dev
terraform plan -out=tfplan
# Review network_profile.network_policy
terraform apply tfplan
```

### Validation

```bash
az aks show -g <RESOURCE_GROUP> -n <CLUSTER_NAME> \
  --query "networkProfile.networkPolicy" -o tsv
# Expected: azure
```

**Deferred until live Azure.**

---

## Step 15.3: Sync GitOps and verify objects — **Apply later**

### Goal

Argo CD applies NetworkPolicies into `boutique-dev` (then stage/prod on promote/sync).

### Commands

```bash
# After push + Argo sync (dev Application auto-sync)
kubectl get networkpolicy -n boutique-dev
kubectl describe networkpolicy default-deny-ingress -n boutique-dev
```

### Expected output

Twelve policies in `boutique-dev`; overlays for stage/prod inherit the same base after sync.

### Validation

- [ ] `kubectl get netpol -n boutique-dev` shows all allow-* + default-deny
- [ ] Storefront HTTPS still works: `curl -fsS https://dev-boutique.<DNS_ZONE>/` (or browser)
- [ ] Optional: `./tests/integration/dev-smoke.sh` still passes

---

## Step 15.4: Negative test (isolation proof) — **Apply later**

### Goal

Prove a non-allowed client cannot reach a backend.

### Commands

```bash
# From a throwaway pod that is NOT in the allow list for redis-cart
kubectl -n boutique-dev run netpol-probe --rm -it --restart=Never \
  --image="<ACR_LOGIN_SERVER>/busybox:1.36.1" \
  --command -- wget -T 3 -qO- redis-cart:6379 || true
```

### Expected output

Connection **times out** or fails (not a Redis handshake). Contrast: `cartservice` pods may still reach Redis.

**Caution:** Use a **signed ACR** busybox image so Kyverno allows the probe pod. Delete the probe if it sticks.

### Validation

- [ ] Unauthorized client cannot open redis-cart:6379
- [ ] Legitimate path still works (add to cart in UI)

---

## Step 15.5: Rollback

| Action | How |
|--------|-----|
| Soft disable | Remove `networkpolicies` from `base/kustomization.yaml`, sync Argo |
| Or delete policies | `kubectl delete netpol --all -n boutique-dev` (emergency) |
| Keep TF | Leave `aks_network_policy` as-is; policies optional independently |

Do **not** flip `network_policy` off/on casually on a lived cluster without reading Azure recreate implications.

---

## Out of scope (this package)

| Item | Notes |
|------|-------|
| Egress default-deny | Stretch — needs DNS + same-ns egress rules |
| Cross-namespace Boutique calls | Not in app design |
| Cilium / Calico advanced | TF allows `calico`; pilot docs use `azure` |
| NetworkPolicy unit tests in CI | Optional follow-up (kubeconform / Kyverno not a substitute) |

---

## End-to-end validation checklist

### Scaffold (no Azure)

- [x] Policies under `gitops/apps/boutique/base/networkpolicies/`
- [x] Included from base kustomization
- [x] `aks_network_policy` / module `network_policy` wired (default `null`)
- [ ] `kubectl kustomize gitops/apps/boutique/overlays/dev` succeeds locally

### Apply later (live)

- [ ] `networkProfile.networkPolicy == azure`
- [ ] Policies present in boutique namespaces
- [ ] Storefront + smoke OK
- [ ] Negative probe against redis-cart fails

---

## Related docs

| Doc | Role |
|-----|------|
| [10-boutique-dev.md](10-boutique-dev.md) | App deploy |
| [14-pr-ci.md](14-pr-ci.md) | PR gates (yamllint covers new YAML) |
| [06-network-design.md](../architecture/06-network-design.md) | Network architecture |
| [threat-model.md](../security/threat-model.md) | East-west residual risk |
