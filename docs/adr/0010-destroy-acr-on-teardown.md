# ADR-0010: Destroy ACR on teardown

## Status

Accepted

## Context

Lab cost must stop cleanly when the project is not in use.

## Decision

Phase 14 teardown **destroys ACR** along with AKS and other billable resources.

## Consequences

- **Positive:** No ongoing registry storage cost.
- **Negative:** Full rebuild requires re-running mirror/sign pipeline (Phase 9).
