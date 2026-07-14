# ADR-0009: Mirror upstream v0.10.5 images

## Status

Accepted

## Context

FR-04 requires scan/sign/push in ADO. Boutique images are published by Google to Artifact Registry, not built in this repo.

## Decision

**Mirror** each v0.10.5 service image from `us-central1-docker.pkg.dev/google-samples/microservices-demo` to ACR, then Trivy scan and cosign sign by digest.

## Consequences

- **Positive:** Reproducible upstream version; satisfies Kyverno ACR allowlist.
- **Negative:** Mirror pipeline must handle 11+ images; rebuild after ACR teardown.
