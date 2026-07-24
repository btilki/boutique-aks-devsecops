# ADR-0013: Scaffold-first Phase 15+ (no live Azure required)

## Status

Accepted

## Context

Setup Topics **00–13** were lived and the Azure test torn down. The repo remains a reference platform. Fuller DevSecOps controls (PR CI, NetworkPolicies, IaC scan, SBOM/attestations, runtime security, namespace/KV hardening, optional DAST) were deferred or skipped (Roadmap Phase 13).

Rebuilding Azure solely to author those features is costly and unnecessary for documentation and file layout.

## Decision

Deliver Phase **15–22** in two modes:

1. **Scaffold first** — commit pipelines, policies, GitOps/TF stubs, setup Topics **14–20**, and ADRs without `terraform apply` or a live cluster.
2. **Apply later** — after a future rebuild of Topics 00–12, execute Topics 14–20 and mark live validation separately.

Roadmap Phase 13 remains **skipped** historically; Phase **15+** supersedes that hardening backlog.

## Consequences

- **Positive:** Continuous repo improvement without burn rate; clear package order; teachable future setup path.
- **Negative:** Scaffold ✅ ≠ cluster-proven; readers must distinguish “files present” from “lived on AKS.”
- **Follow-up:** Each setup topic must label **Apply later** / **Deferred validation** steps explicitly.
