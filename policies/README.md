# Policies

## Purpose

Kyverno admission policies and test fixtures, separated from GitOps install manifests.

## Contents

- `kyverno/cluster/` — registry allowlist, deny `:latest`, verifyImages, PSS baseline
- `kyverno/namespace/` — documented exceptions (if any)
- `tests/` — `kyverno test` resources

## Prerequisites

- Kyverno controller running (Phase 8)

## Usage

[docs/setup/08-admission-policies.md](../docs/setup/08-admission-policies.md)

## Timing

SETUP_REQUIRED — Phase 8 (controller + policies).

## Numbering

Roadmap **Phase** numbers differ from Setup **Topic** numbers (for example Roadmap Phase 14 teardown = Setup Topic 13). See [ROADMAP.md](../ROADMAP.md) and [docs/setup/README.md](../docs/setup/README.md).
