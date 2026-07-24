# ADR-0014: SPDX SBOM + cosign attestations (key-based)

## Status

Accepted (scaffold — apply with Topic 17)

## Context

The lived pilot signs images with cosign but does not attach an SBOM or vulnerability attestation. Roadmap Phase 19 / Package 5 adds supply-chain depth without rebuilding Boutique from source (ADR-0009).

## Decision

1. Generate an **SPDX JSON** SBOM per mirrored service image with **Trivy** (`trivy image --format spdx-json`) — same tool pin as the CRITICAL vuln gate.
2. Attach the SBOM with **`cosign attest --type spdxjson`**, same Key Vault key pair as signing, **`--tlog-upload=false`**.
3. Verify in CI with **`cosign verify-attestation --type spdxjson --insecure-ignore-tlog`**.
4. Add Kyverno ClusterPolicy `verify-sbom-attestations` that checks predicate type `https://spdx.dev/Document` with the same public key; start in **Audit**, switch to **Enforce** after a full re-mirror.

## Consequences

- **Positive:** Digests carry inspectable SBOMs; admission can require attestation; no new signing key.
- **Negative:** Pipeline runtime grows (~SBOM gen × 11 images); Kyverno Enforce before attestations exist will block deploys.
- **Not chosen:** Syft-only SBOM (extra binary); Trivy vuln cosign attestations as the primary artifact (can add later); keyless/Rekor (ADR-0005).
