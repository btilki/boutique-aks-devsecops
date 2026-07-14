# ADR-0007: No service mesh in v1

## Status

Accepted

## Context

Scope prioritizes supply chain, GitOps, and observability depth over mesh features.

## Decision

Deploy **without** a service mesh (no Istio/Linkerd) in v1.

## Consequences

- **Positive:** Lower ops burden and cost.
- **Negative:** No mTLS or advanced traffic management between services.
