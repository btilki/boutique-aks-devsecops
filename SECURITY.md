# Security policy

## Secrets

- **Never** commit secrets, private keys, `cosign.key`, or real `terraform.tfvars` to Git.
- Pipeline authentication uses **Azure DevOps OIDC** — no long-lived service principal secrets in variables.
- Application and platform secrets are stored in **Azure Key Vault** and mounted via **Secrets Store CSI** with Workload Identity.
- Cosign signing keys live in Key Vault (or ADO secure files as documented fallback).

## Reporting vulnerabilities

This is a learning/reference repository. If you discover a security issue in project configuration:

1. Do not open a public issue with exploit details.
2. Contact the repository owner directly.
3. Allow reasonable time for remediation before disclosure.

## Supply chain

- Images are mirrored from upstream Online Boutique v0.10.5, scanned with **Trivy** (fail on CRITICAL), and signed with **cosign**.
- **Kyverno** enforces ACR allowlist, denies `:latest`, and verifies signatures at admission.
- See [docs/security/supply-chain.md](docs/security/supply-chain.md) (authored in Phase 9).

## Least privilege

- Humans: Entra ID + Azure RBAC + AKS AAD RBAC.
- Pipeline: federated credential scoped to ACR push and required Key Vault secret read.
- Workloads: Workload Identity per service where secrets are needed.

## Teardown

Phase 14 destroys billable resources including **ACR** to stop ongoing cost. See [docs/setup/13-teardown.md](docs/setup/13-teardown.md).
