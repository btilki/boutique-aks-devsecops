# Tests

## Purpose

Validation scripts for Terraform, Kubernetes manifests, Kyverno policies, and end-to-end smoke tests.

## Contents

| Directory | Purpose |
|-----------|---------|
| `terraform/` | `terraform validate`, post-apply checks |
| `kubernetes/` | kubeconform / manifest lint |
| `policies/` | Kyverno test runner |
| `integration/` | dev/stage/prod smoke (Topic 10+) |

## Usage

Run after matching phase validation in [docs/implementation/plan.md](../docs/implementation/plan.md).

## Timing

SETUP_REQUIRED (`README`) Phase 0; scripts per phase.
