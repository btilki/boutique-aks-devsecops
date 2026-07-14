# ADR-0002: Single AKS cluster, multi-namespace environments

## Status

Accepted

## Context

Budget and solo-builder constraints require minimal Azure spend while demonstrating dev/stage/prod promotion.

## Decision

Run **one AKS cluster** in `germanywestcentral` with namespaces `boutique-dev`, `boutique-stage`, `boutique-prod`.

## Consequences

- **Positive:** Lowest cost; simpler operations.
- **Negative:** Shared blast radius; not production HA isolation.
