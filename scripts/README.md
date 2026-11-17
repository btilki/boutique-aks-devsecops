# Scripts

## Purpose

Guarded operational helpers. **Do not** replace documented setup steps in `docs/setup/`.

## Contents

| Script | Phase |
|--------|-------|
| `bootstrap-tf-backend.sh` | 1 |
| `verify-oidc-trust.sh` | 4 |
| `register-ado-sc-federation.sh` | 4 |
| `operations/teardown.sh` | 13 |

## Usage

Each script documents required flags (e.g. teardown `--confirm`) in matching setup/runbook topics.

## Timing

SETUP_REQUIRED / FEATURE_REQUIRED per phase.

## Numbering

Roadmap **Phase** numbers differ from Setup **Topic** numbers (for example Roadmap Phase 14 teardown = Setup Topic 13). See [ROADMAP.md](../ROADMAP.md) and [docs/setup/README.md](../docs/setup/README.md).
