# ADR-0005: Key-based cosign 2.2.x signing

## Status

Accepted

## Context

Kyverno 1.12.x `verifyImages` is stable with key-based cosign. Keyless/cosign v3 adds complexity for a solo test.

## Decision

Sign with **cosign 2.2.4** using a key pair stored in Key Vault. Pipeline uses `--tlog-upload=false`. Kyverno sets `ignoreTlog: true` and `ignoreSCT: true`.

## Consequences

- **Positive:** Predictable verify path with Kyverno 1.12.
- **Negative:** Key rotation and secure storage are operator responsibilities.
