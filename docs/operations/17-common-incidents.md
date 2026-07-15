# Common incidents

**Audience:** L3 — Operator
**Applies to:** Production-pilot lab
**Prerequisites:** [07-incident-response.md](07-incident-response.md)
**Estimated time:** 10–45 minutes per playbook
**Risk level:** Medium–High

## Purpose

First-response playbooks for the highest-likelihood failures.

## When to use / When not to use

**Use** immediately after SEV assignment.
**Do not** skip diagnosis and jump to teardown.

---

## Playbook 1 — Pod CrashLoopBackOff

**Purpose:** Restore a crashing Boutique/platform pod.

**Diagnosis:**

```bash
kubectl get pods -n boutique-<env>
kubectl describe pod -n boutique-<env> <pod>
kubectl logs -n boutique-<env> <pod> --tail=100
kubectl logs -n boutique-<env> <pod> --previous
```

**Common fix:** Bad image digest / Kyverno deny / missing dependency → [03-rollback.md](03-rollback.md) or fix config in Git.

**Validation:** Pod Running/Ready; smoke pass.

**Recovery:** Scale optional services down if capacity-related Pending masquerades as crash.

**Prevention:** Digest pins; resource limits; stage smoke before prod.

---

## Playbook 2 — GitOps OutOfSync / sync error

**Purpose:** Restore Argo CD reconciliation.

**Diagnosis:**

```bash
kubectl get application -n argocd
kubectl describe application boutique-<env> -n argocd | tail -40
```

**Common fix:** Manifest schema / AppProject destination / SSA for CRDs → [argocd-sync.md](../troubleshooting/argocd-sync.md); sync with prune carefully.

**Validation:** Synced + Healthy.

**Recovery:** Revert last GitOps commit.

**Prevention:** Validate kustomize/helm render locally before push.

---

## Playbook 3 — Certificate expired / TLS errors

**Purpose:** Restore HTTPS trust.

**Diagnosis:**

```bash
kubectl get certificate -A
kubectl describe certificate -A | grep -A20 'Status:\|Message:\|Reason:'
```

**Common fix:** DNS-01 Challenge / TXT → [14-certificate-rotation.md](14-certificate-rotation.md) · [cert-manager-dns01.md](../troubleshooting/cert-manager-dns01.md).

**Validation:** Browser + `openssl s_client` dates OK.

**Recovery:** Temporary HTTP only is **not** recommended; fix issuer.

**Prevention:** Act on `IngressCertExpiringSoon`.

---

## Playbook 4 — Node NotReady

**Purpose:** Restore capacity and schedule pods.

**Diagnosis:**

```bash
kubectl get nodes
kubectl describe node <node> | tail -50
kubectl get pods -A --field-selector=status.phase=Pending
```

**Common fix:** Wait for VMSS repair; cordon/drain peer; reclaim pods ([04](04-scaling.md), [12](12-maintenance.md)).

**Validation:** Node Ready; Pending cleared.

**Recovery:** Azure portal restart VMSS instance if hung.

**Prevention:** Watch disk pressure / quota before scale.

---

## Playbook 5 — High memory / OOMKilled

**Purpose:** Stop OOM crash loops.

**Diagnosis:**

```bash
kubectl describe pod -n <ns> <pod> | grep -i oom
kubectl top pod -n <ns>
```

**Common fix:** Raise limits via overlay patch **or** reduce replicas of non-critical services; restart deployment.

**Validation:** No OOM events; Ready.

**Recovery:** Rollback resource patch if thrashing.

**Prevention:** Keep slim lab profile; Grafana CPU/memory panels.

---

## Playbook 6 — Kyverno admission deny / Image fails verify

**Purpose:** Unblock legitimate deploys without disabling policy.

**Diagnosis:**

```bash
kubectl get events -n boutique-<env> | grep -i kyverno
# Compare image to ACR allowlist + signature
```

**Common fix:** Use signed ACR digest; refresh public key; [kyverno-admission.md](../troubleshooting/kyverno-admission.md) · [image-signature.md](../troubleshooting/image-signature.md).

**Validation:** Dry-run apply succeeds; sync Healthy.

**Recovery:** Do **not** set validationFailureAction to Audit as a permanent fix.

**Prevention:** Pipeline always signs; keep Kyverno PEM in sync.

---

## Playbook 7 — Terraform state lock

**Purpose:** Clear a stale lock after crashed apply (with caution).

**Diagnosis:**

```bash
cd terraform/environments/dev
terraform plan
# Error mentions lease / blob lease
```

**Common fix:** Confirm no other `terraform` process; then `terraform force-unlock <LOCK_ID>` **only** if lock owner is dead.

**Validation:** Plan runs; no concurrent applies.

**Recovery:** If unsure, wait and retry — wrong unlock risks state corruption.

**Prevention:** `-lock-timeout`; single operator.

---

## End-to-end validation

Return to [08-health-checks.md](08-health-checks.md).

## Rollback (section-level)

Per playbook recovery.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| See [10-alerting.md](10-alerting.md) | Boutique / Cluster | Loki namespace filters |

## Security notes

Never disable signature verify to clear a SEV.

## Automation opportunities

Map each alert name → playbook heading via `runbook_url`.
