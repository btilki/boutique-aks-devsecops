# ADR-0006: Kustomize for Online Boutique

## Status

Accepted

## Context

Online Boutique v0.10.5 ships Kubernetes manifests. We need digest-pinned images and env-specific ingress without forking Helm charts.

## Decision

Use **Kustomize** base (from upstream v0.10.5) plus overlays for dev/stage/prod.

## Consequences

- **Positive:** Native Argo CD support; clear per-env patches.
- **Negative:** Upstream manifest upgrades require manual base refresh.
