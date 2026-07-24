# ADR-0015: Falco for runtime detection (Defender opt-in)

## Status

Accepted (scaffold — apply with Topic 18)

## Context

The lived pilot has no runtime threat detection. Package 6 / Phase 20 needs a teachable control that fits the pilot: single cluster, cost-conscious, in-cluster logs ([ADR-0012](0012-loki-in-cluster-logging.md)).

Microsoft Defender for Containers is Azure-native but typically pairs with **Log Analytics** (ingestion cost) and was previously only ignored for Terraform drift — not provisioned as a first-class module.

## Decision

1. **Primary:** Deploy **Falco** via Argo CD (`gitops/platform/falco/`) using the **modern eBPF** driver, JSON logs to stdout → Promtail → Loki (same path as other platform logs).
2. **Secondary:** Document **Defender for Containers** as an **opt-in** Azure control (subscription/portal or future TF); do **not** enable it by default in `terraform/environments/dev`.
3. Keep AKS `lifecycle.ignore_changes` on `microsoft_defender` so subscription-level Defender does not fight Terraform when left unmanaged.

## Consequences

- **Positive:** Runtime syscall visibility without Log Analytics bill; GitOps-managed; aligns with Loki/Grafana ops.
- **Negative:** Falco needs privileged / elevated capabilities on nodes; eBPF support depends on AKS node kernel; not a full Azure Defender posture score.
- **Not chosen:** Falco + Defender both on by default (cost/complexity); Falcosidekick→Slack as required (optional stretch).
