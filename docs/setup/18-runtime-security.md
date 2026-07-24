# 18 — Runtime Security (Falco + Defender opt-in)

**Audience:** L2 — Implementer
**Estimated time:** 45–75 minutes after Topics 05 + 11
**Prerequisites:** [05-gitops-bootstrap.md](05-gitops-bootstrap.md) ✅ · [11-observability.md](11-observability.md) recommended (Loki/Promtail)
**Creates:** Falco DaemonSet via Argo CD; optional Defender for Containers (documented, not default)
**Related ADRs:** [0015](../adr/0015-falco-runtime-detection.md), [0012](../adr/0012-loki-in-cluster-logging.md)
**Mode:** GitOps + docs scaffolded. Live Falco needs a rebuilt cluster (**Apply later**).

---

## Topic goal

When this topic is complete:

1. **Falco** runs on every node (`namespace: falco`) with **modern eBPF**.
2. Falco emits **JSON** logs scraped into **Loki** (same path as other workloads).
3. Alert **FalcoDaemonSetUnavailable** is present in monitoring extras.
4. You understand **Defender for Containers** is opt-in only ([DEFENDER-OPT-IN.md](../../terraform/modules/aks/DEFENDER-OPT-IN.md)).

## Why this topic is required

Admission (Kyverno) and CI (Trivy/cosign) do not see malicious *behavior* after a signed image starts. Runtime detection closes that gap for the DevSecOps portfolio story.

---

## Before you begin

```bash
cd /path/to/boutique-aks-devsecops
ls gitops/platform/falco/
grep -n falco gitops/platform/kustomization.yaml gitops/projects/platform.yaml
grep -n falco_chart versions.yaml
```

**Expected:** `Application.yaml`, `values.yaml`, `README.md`; listed from platform kustomization; `falco` destination on AppProject `platform`; chart pin **9.1.0**.

---

## Step 18.1: Review ADR-0015 and values

### Goal

Confirm Falco-primary vs Defender-opt-in and eBPF settings.

### Commands

```bash
cat docs/adr/0015-falco-runtime-detection.md
cat gitops/platform/falco/values.yaml
```

### Validation

- [ ] `driver.kind: modern_ebpf`
- [ ] `falco.json_output: true`
- [ ] No Falcosidekick/Slack required for v1 of this topic

---

## Step 18.2: Confirm GitOps wiring

### Goal

`platform-root` will sync the Falco Application.

### Commands

```bash
grep -n falco gitops/platform/kustomization.yaml
grep -n "namespace: falco" gitops/projects/platform.yaml
cat gitops/platform/monitoring/extras/alerts/runtime-security.yaml | head -20
```

### Validation

- [ ] `falco/Application.yaml` in platform kustomization
- [ ] AppProject allows destination namespace `falco`
- [ ] `runtime-security` alert listed in extras kustomization

---

## Step 18.3: Sync Falco — **Apply later**

### Goal

Deploy Falco and verify DaemonSet health.

### Commands

```bash
# After push + Argo sync (or refresh platform-root)
kubectl get application falco -n argocd
kubectl get ds,pods -n falco
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=50
```

### Expected

- Application Synced/Healthy
- One Falco pod per node (system + user pools as scheduled)
- JSON lines in logs (rules firing may be quiet until activity)

### Validation

- [ ] `kubectl get ds -n falco` Ready == Desired
- [ ] Grafana Explore → Loki: `{namespace="falco"}` returns lines (if Promtail scrapes all namespaces — confirm Promtail config)

**If modern eBPF fails:** check node OS/kernel; try chart notes for `driver.kind=auto`; see Falco troubleshooting on Artifact Hub. Do not fall back to unsigned kernel modules without documenting the change.

---

## Step 18.4: Trigger a safe demo event — **Apply later** (optional)

### Goal

Prove a rule can fire (noisy — use only in test).

```bash
# Example: shell in a Boutique pod (may match "Terminal shell in container" style rules)
kubectl -n boutique-dev exec -it deploy/frontend -- /bin/sh -c 'echo falco-demo'
```

Then search Loki for `falco-demo` or priority fields. Tune or disable noisy rules before prod-like demos.

---

## Step 18.5: Defender for Containers (optional) — **Apply later**

### Goal

Only if you explicitly want Azure Defender posture (accept cost).

Follow [terraform/modules/aks/DEFENDER-OPT-IN.md](../../terraform/modules/aks/DEFENDER-OPT-IN.md). Do **not** treat Defender as required for Topic 18 done.

### Validation

- [ ] Skipped (default) **or** Defender Containers plan enabled and drift ignored by Terraform

---

## Rollback

1. Remove `falco/Application.yaml` from `gitops/platform/kustomization.yaml` (or delete Argo Application `falco`) and sync
2. Delete namespace `falco` if leftover
3. Remove or silence `runtime-security` PrometheusRule if desired

---

## End-to-end validation checklist

### Scaffold

- [x] Falco Application + values + ADR-0015
- [x] AppProject destination + platform kustomization
- [x] FalcoDaemonSetUnavailable alert
- [x] Defender opt-in note under AKS module

### Apply later

- [ ] Falco DaemonSet Ready
- [ ] Logs visible in Loki
- [ ] Alert expression resolves (even if not firing)

---

## Related docs

| Doc | Role |
|-----|------|
| [11-observability.md](11-observability.md) | Loki / Promtail |
| [gitops/platform/falco/README.md](../../gitops/platform/falco/README.md) | Component README |
| [17-common-incidents.md](../operations/17-common-incidents.md) | Incident patterns |
| [19-namespace-hardening.md](19-namespace-hardening.md) | Next hardening package |
