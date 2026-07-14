# ADR-0001: Azure as sole cloud provider

## Status

Accepted

## Context

The project must demonstrate Azure DevSecOps with AKS, ACR, Key Vault, Azure DNS, and Azure DevOps OIDC.

## Decision

Use **Microsoft Azure only** for all infrastructure and platform services.

## Consequences

- **Positive:** Native Workload Identity, Key Vault CSI, and ADO federation.
- **Negative:** No multi-cloud portability without significant rework.
