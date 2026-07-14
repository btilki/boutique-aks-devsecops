# ADR-0003: Kyverno for admission control

## Status

Accepted

## Context

Workload admission must enforce registry allowlist, deny `:latest`, verify cosign signatures, and apply Pod Security baseline.

## Decision

Use **Kyverno** ClusterPolicy `verifyImages` and validation rules. Do not enable Azure Policy for Kubernetes in v1.

## Consequences

- **Positive:** Kubernetes-native policies; `kyverno test` in CI.
- **Negative:** No subscription-level guardrails; policy/Kyverno version alignment required.
