# ADR-0017: Optional ZAP baseline DAST (advisory by default)

## Status

Accepted (scaffold — apply with Topic 20)

## Context

Package 8 (Phase 22) adds dynamic application security testing against the lived Boutique storefront. The app is mirrored upstream (ADR-0009); DAST finds runtime/HTTP issues CI image scans cannot. Full authenticated/API scans are out of scope for the pilot.

## Decision

1. Provide a **manual** Azure DevOps pipeline (`azure-pipelines-dast.yml`) that runs **OWASP ZAP baseline** (`zap-baseline.py`) against a configurable HTTPS target (default: `https://dev-boutique.biroltilki.art`).
2. Default **`dastFailOnWarn: false`** — publish HTML/JSON reports as artifacts; do not block delivery unless the operator opts into failing the job.
3. Do **not** wire DAST into every PR or `main` supply-chain run (noise + needs live ingress).
4. Only scan hostnames **you operate** (this project's Boutique FQDNs).

## Consequences

- **Positive:** Completes the DevSecOps portfolio loop (SAST/IaC/container + runtime + DAST); low coupling to mirror pipeline.
- **Negative:** Requires live cluster/DNS/TLS; baseline is shallow vs full scan; false positives need triage.
- **Not chosen:** ZAP full scan as merge gate; Burp Enterprise; scanning stage/prod by default.
