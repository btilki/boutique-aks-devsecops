# Maintenance

**Audience:** L3 — Operator
**Applies to:** Nodes, GitOps sync, planned downtime
**Prerequisites:** Capacity awareness; optional maintenance window communication
**Estimated time:** 30–90 minutes
**Risk level:** Medium

## Purpose

Perform planned work (node recycle, chart bumps prep, capacity reclaim) with minimal customer-facing impact on the lab hostnames.

## When to use / When not to use

**Use** for node upgrades, disk pressure, or controlled Argo pauses.
**Do not** drain the only Ready user node without ensuring workloads can schedule elsewhere.

## Prerequisites

- [ ] Announce window to yourself / stakeholders
- [ ] Confirm `kubectl get nodes` and pod budget

## Procedure

### Step 1: Pause risky promotions

**Commands / GUI:** Do not approve ADO prod environment; avoid Argo sync on prod during node drain.

**Validation:** No in-flight promote.

### Step 2: Cordon and drain (user node)

**Commands:**

```bash
NODE=<aks-user-...-vmss00000x>
kubectl cordon "$NODE"
kubectl drain "$NODE" --ignore-daemonsets --delete-emptydir-data --timeout=300s
# perform host maintenance / wait for replace
kubectl uncordon "$NODE"
```

**Validation:** No Pending pods stuck for core services; frontend Ready.

**Expected outcome:** Workloads rescheduled to remaining capacity (may require scaling others to 0 first — [04-scaling.md](04-scaling.md)).

**Recovery steps:** Uncordon immediately if drain fails mid-way; scale down non-critical envs.

**Best practices:** Drain one node at a time on a 2-node lab.

### Step 3: Capacity reclaim (GitOps)

Prefer overlay replica patches over ad-hoc deletes of monitoring.

## End-to-end validation

[08-health-checks.md](08-health-checks.md) smokes for affected envs.

## Rollback (section-level)

Uncordon nodes; restore replica patches; re-sync Argo.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| `NodeNotReady` | Cluster Overview | — |

## Security notes

`--delete-emptydir-data` wipes Redis cart emptyDir — acceptable for demo.

## Automation opportunities

AKS planned maintenance events → calendar reminder.
