# 08 — Admission Policies (Kyverno)

**Audience:** L2 — Implementer
**Estimated time:** 120 minutes
**Prerequisites:** [05-gitops-bootstrap.md](05-gitops-bootstrap.md) ✅ · [07-secrets-csi.md](07-secrets-csi.md) recommended (remove `csi-test` pod before enforce)
**Creates:** Kyverno 1.12.6, five ClusterPolicies, policy test suite
**Related ADRs:** [0003](../adr/0003-kyverno-admission.md), [0005](../adr/0005-cosign-key-based-signing.md)

---

## Topic goal

When this topic is complete, **Kyverno** enforces cluster admission policies: **ACR allowlist**, **deny `:latest`**, **cosign signature verification** (key placeholder until Topic 09), **Pod Security baseline**, and **no privileged/hostPath** access. `kyverno test` passes for validation policies.

## Why this topic is required

Admission control is the runtime enforcement layer for supply-chain decisions. CI (Topic 09) signs images; Kyverno ensures only compliant workloads run. Without admission, unsigned or public-registry images could deploy despite pipeline gates.

---

## Before you begin

- [ ] Argo CD healthy; `platform-root` syncing
- [ ] `terraform output acr_name` known
- [ ] Optional: remove `csi-test` test pod/manifests (non-ACR image) before enforcing
- [ ] Kyverno CLI installed (`kyverno version`)

```bash
cd terraform/environments/dev
terraform output -raw acr_name
kyverno version
kubectl get pods -n kyverno 2>/dev/null || echo "Kyverno not installed yet"
```

---

## Step 8.1: Review policies and install manifests

### Goal

Understand policy scope and GitOps delivery paths.

### Why this step is required

Policies apply cluster-wide; mistakes can block platform components.

### Commands

```bash
ls policies/kyverno/cluster/
ls gitops/platform/kyverno/
cat policies/kyverno/cluster/00-registry-allowlist.yaml | head -25
```

### Expected output

Five ClusterPolicy files + Kyverno Helm Application + `kyverno-policies` Application.

### Validation

- [ ] Platform namespaces excluded from ACR allowlist where documented
- [ ] `verify-image-signatures` includes `ignoreTlog` / `ignoreSCT`

---

## Step 8.2: Patch policy placeholders

### Goal

Set ACR name and prepare cosign public key slot.

### Why this step is required

Policies use literal registry patterns; wrong ACR name blocks all Boutique deploys.

### Commands

```bash
ACR_NAME=$(cd terraform/environments/dev && terraform output -raw acr_name)
echo "ACR_NAME=${ACR_NAME}"
```

Replace `<ACR_NAME>` in:

- `policies/kyverno/cluster/00-registry-allowlist.yaml`
- `policies/kyverno/cluster/02-verify-image-signatures.yaml`

Update test fixtures if your ACR name differs from `acrboutiquedevgwc` in `policies/tests/resources/*.yaml`.

**Cosign public key (Topic 09):** leave `<COSIGN_PUBLIC_KEY_PEM>` until key generated, or paste `cosign.pub` now if already created.

Update `gitops/platform/kyverno/policies-application.yaml` and `Application.yaml` GitHub `repoURL` (if not patched in Topic 05).

Commit and push.

### Validation

- [ ] No `<ACR_NAME>` literals remain in cluster policies
- [ ] Changes pushed to Git

---

## Step 8.3: Sync Kyverno controller

### Goal

Install Kyverno admission controller via GitOps.

### Why this step is required

Policies require CRDs and webhook from the Kyverno chart.

### Commands

```bash
argocd app sync kyverno
argocd app wait kyverno --health --timeout 600
kubectl get pods -n kyverno
kubectl get crd clusterpolicies.kyverno.io
```

### Expected output

Kyverno pods **Running**; ClusterPolicy CRD registered.

### Validation

```bash
kubectl get validatingwebhookconfigurations | grep kyverno
```

- [ ] Webhook configurations present
- [ ] `kyverno` Application Healthy

---

## Step 8.4: Sync Kyverno policies

### Goal

Apply ClusterPolicies from `policies/kyverno/`.

### Why this step is required

Controller alone does not enforce rules until policies exist.

### Commands

```bash
argocd app sync kyverno-policies
argocd app wait kyverno-policies --health --timeout 300
kubectl get clusterpolicy
```

### Expected output

```text
NAME                              ADMISSION   BACKGROUND
registry-allowlist                true        true
deny-latest-tag                   true        true
verify-image-signatures           true        true
require-pod-security-baseline     true        true
block-privileged-host-access      true        true
```

### Validation

- [ ] Five ClusterPolicies listed
- [ ] `kubectl describe clusterpolicy registry-allowlist` shows Ready

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Invalid policy YAML | Placeholder PEM | Fix `02-verify-image-signatures.yaml` or use valid PEM |
| Sync failed | Repo auth | Fix Argo CD repository credentials |

---

## Step 8.5: Run Kyverno CLI tests

### Goal

Validate policies offline against test fixtures.

### Why this step is required

Fast feedback before live admission tests.

### Commands

```bash
cd policies/tests
kyverno test kyverno-test.yaml
```

### Expected output

```text
Test Summary: All tests passed
```

### Validation

- [ ] CLI tests pass (signature policy excluded from CLI suite until Topic 09)

---

## Step 8.6: Live admission validation

### Goal

Confirm API server denies non-compliant pods.

### Why this step is required

Proves webhooks enforce at admission time.

### Commands

```bash
kubectl apply -f policies/tests/resources/deny-non-acr-image.yaml --dry-run=server
kubectl apply -f policies/tests/resources/deny-latest-tag.yaml --dry-run=server
kubectl apply -f policies/tests/resources/allow-compliant-workload.yaml --dry-run=server
```

### Expected output

- `deny-non-acr-image` → **Error** from Kyverno (`registry-allowlist`)
- `deny-latest-tag` → **Error** from Kyverno (`deny-latest-tag`)
- `compliant-pod` → **configured** (allowed) — signature verify may fail later if key enforced and image unsigned

### Validation

- [ ] Deny tests blocked
- [ ] Compliant pod accepted (or only signature policy blocks if PEM configured)

---

## Step 8.7: Signature verification readiness (Topic 09 handoff)

### Goal

Document state of cosign verify policy before CI signing.

### Why this step is required

Full signature enforcement requires signed images in ACR and public key in policy.

### Commands

If cosign key not yet created:

- Keep policy file with valid PEM after Topic 09
- Re-sync `kyverno-policies` after updating PEM

Validate signing path:

```bash
# After Topic 09
cosign verify --key cosign.pub --insecure-ignore-tlog <ACR_IMAGE@sha256>
```

See [image-signature.md](../troubleshooting/image-signature.md).

### Validation

- [ ] Team understands signature policy completes in Topic 09/10

---

## Topic validation (end-to-end)

```bash
kubectl get pods -n kyverno
kubectl get clusterpolicy
cd policies/tests && kyverno test kyverno-test.yaml
kubectl apply -f policies/tests/resources/deny-non-acr-image.yaml --dry-run=server
```

**Success criteria:**

- [ ] Kyverno Healthy
- [ ] Five ClusterPolicies active
- [ ] CLI tests pass
- [ ] Live deny/allow tests behave as expected

Update [Setup Index](README.md) Topic 08 to ✅ when complete.

---

## Topic troubleshooting

- [kyverno-admission.md](../troubleshooting/kyverno-admission.md)
- [image-signature.md](../troubleshooting/image-signature.md)

---

## Next step

➡️ Continue to **[09-ci-pipeline.md](09-ci-pipeline.md)** (Topic 09) to mirror, scan, and sign Boutique images.

After signing, update `02-verify-image-signatures.yaml` PEM and re-sync policies before **[10-boutique-dev.md](10-boutique-dev.md)**.
