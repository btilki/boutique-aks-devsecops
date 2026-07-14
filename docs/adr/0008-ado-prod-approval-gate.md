# ADR-0008: ADO environment approval for prod

## Status

Accepted

## Context

Prod promotion must have a human gate suitable for a solo builder without PR reviewer overhead.

## Decision

Require **Azure DevOps environment approval** before prod overlay updates. Stage uses manual Argo sync only (no ADO gate).

## Consequences

- **Positive:** Simple, auditable prod gate in ADO.
- **Negative:** No Git-level CODEOWNERS enforcement for prod.
