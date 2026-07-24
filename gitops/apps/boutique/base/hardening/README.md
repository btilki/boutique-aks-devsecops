# Namespace hardening helpers (Topic 19 / ADR-0016)

| File | Role |
|------|------|
| `limit-range.yaml` | Default/max container CPU/memory |
| `resource-quota.yaml` | Namespace pod/CPU/memory caps |

PSA labels are on `overlays/*/namespace.yaml` (`pod-security.kubernetes.io/*`).

Setup: [docs/setup/19-namespace-hardening.md](../../../../../docs/setup/19-namespace-hardening.md)
