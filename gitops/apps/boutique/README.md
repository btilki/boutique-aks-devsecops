# Online Boutique (GitOps)

## Purpose

Kustomize packaging for [Online Boutique v0.10.5](https://github.com/GoogleCloudPlatform/microservices-demo/releases/tag/v0.10.5).

## Contents

- `base/` — upstream-derived manifests; ACR image refs; patches for redis/busybox policy compliance; **NetworkPolicies** (`base/networkpolicies/`, Topic 15); **hardening** quotas (`base/hardening/`, Topic 19)
- `overlays/dev/` — `dev-boutique.biroltilki.art`, auto-sync
- `overlays/stage/` — `stage-boutique.biroltilki.art`, manual sync
- `overlays/prod/` — `boutique.biroltilki.art`, manual sync + ADO approval before Git update

## Prerequisites

- Signed images in ACR (Phase 9)
- Ingress + TLS (Phase 6)
- Kyverno policies (Phase 8)

## Usage

[docs/setup/10-boutique-dev.md](../../../docs/setup/10-boutique-dev.md)

## Timing

Topic 10: `base/`, `overlays/dev/`, `dev-application.yaml`, smoke test.
Topic 12: `overlays/stage/`, `overlays/prod/`, promotion pipeline, smoke tests.
Topic 15: NetworkPolicies in `base/networkpolicies/` (enforce with AKS `network_policy=azure`).
Topic 19: PSA labels on namespaces + ResourceQuota/LimitRange; optional KV ACL/purge.
