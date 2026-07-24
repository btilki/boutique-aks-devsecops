# ADR-0016: Namespace PSA + quotas; optional Key Vault network ACL

## Status

Accepted (scaffold — apply with Topic 19)

## Context

Lived-pilot Boutique namespaces lack Pod Security Admission labels and ResourceQuota/LimitRange. Key Vault is reachable from the public internet (`network_acls` unset / allow), with `purge_protection_enabled = false` for cheap teardown ([ADR-0010](0010-destroy-acr-on-teardown.md) path). Checkov skips document these as pilot tradeoffs (Topic 16).

## Decision

1. Label `boutique-*` namespaces with **Pod Security Admission `enforce=baseline`** (aligns with Kyverno baseline); **warn/audit=`restricted`**.
2. Apply shared **LimitRange** + **ResourceQuota** via Boutique base hardening manifests (all overlays inherit).
3. Extend the Key Vault module with optional **`purge_protection_enabled`** and **`network_acls`** (default **Allow** / purge **false** so rebuild+teardown stay easy). Topic 19 documents flipping to **Deny** + AKS subnet allow-list after enabling **Microsoft.KeyVault** service endpoints on the AKS subnet.
4. When Deny ACL / purge protection are enabled in a long-lived environment, remove the matching Checkov skip IDs.

## Consequences

- **Positive:** Namespace blast-radius controls; clear path to close KV public exposure; PSA reinforces Kyverno.
- **Negative:** Restrictive quotas can block scale-up; KV Deny ACL breaks CSI/ADO if subnet/endpoints misconfigured; purge protection complicates teardown.
- **Not chosen:** `enforce=restricted` PSA (may break redis/busybox patterns); mandatory purge protection on the pilot teardown path.
