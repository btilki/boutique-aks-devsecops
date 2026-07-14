# ADR-0004: Argo CD GitOps

## Status

Accepted

## Context

Platform and application delivery must be declarative, auditable, and digest-promoted.

## Decision

Use **Argo CD** with app-of-apps pattern. Dev auto-sync; stage/prod manual sync.

## Consequences

- **Positive:** Drift detection; Git as source of truth.
- **Negative:** Bootstrap complexity; manual sync for upper environments.
