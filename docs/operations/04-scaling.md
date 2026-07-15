# Scaling

**Audience:** L3 — Operator
**Applies to:** Boutique Deployments; AKS user node pool
**Prerequisites:** Understanding of lab maxPods ≈ 30/node; TF ignore on `node_count`
**Estimated time:** 10–30 minutes
**Risk level:** Medium

## Purpose

Adjust application replicas or node capacity without breaking GitOps or exhausting the 2-node lab.

## When to use / When not to use

**Use** for temporary capacity reclaim or raising frontend replicas in Git.
**Do not** repeatedly `kubectl scale` on auto-synced apps without a Git patch (dev will self-heal).

## Prerequisites

- [ ] `kubectl get pods -A | wc -l` awareness of capacity
- [ ] Prefer overlay patches under `gitops/apps/boutique/overlays/<env>/patches/`

## Procedure

### Step 1: Scale application via GitOps (preferred)

**Commands:**

```bash
# Edit patches/optional-services-replicas.yaml or replicas-patch.yaml
# Commit, push, sync Argo for stage/prod (dev auto)
```

**Validation:** `kubectl get deploy -n boutique-<env>` shows desired replicas.

**Expected outcome:** Pods schedule without `Too many pods`.

**Recovery steps:** Revert patch; scale non-critical namespaces down.

**Best practices:** Keep slim profile until teardown if monitoring must stay up.

### Step 2: Emergency kubectl scale (temporary)

**Commands:**

```bash
kubectl scale deploy/frontend -n boutique-dev --replicas=0   # free slots
```

**Validation:** Pods terminate; Pending pods elsewhere start Running.

**Recovery steps:** Dev auto-heal may restore replicas from Git — patch Git to 0 if lasting.

### Step 3: Node pool autoscaler bounds

**Commands:**

```bash
# Desired bounds live in terraform.tfvars: user_node_min_count / user_node_max_count
# az aks nodepool show -g <rg> --cluster-name <cluster> -n user -o table
```

**Validation:** Live `min`/`max` match intent. Terraform **ignores** live `node_count` drift (lifecycle) — do not expect plan to shrink/grow count alone.

**Expected outcome:** Autoscale between min–max without quota errors.

**Recovery steps:** If `Insufficient regional vCPU quota`, stay at 2 nodes and reclaim pods.

## End-to-end validation

```bash
kubectl describe nodes | grep -A5 'Allocated resources'
kubectl get pods -A --field-selector=status.phase=Pending
```

## Rollback (section-level)

Restore previous replica patches via Git revert; do not force TF apply to “fix” autoscaler count.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| `BoutiqueDevPodsNotReady` | Boutique Overview | — |
| `NodeNotReady` | Cluster Overview | — |

## Security notes

Avoid scheduling privileged workloads to free capacity (Kyverno).

## Automation opportunities

Grafana panel: pods per node / Pending count.
