# Kyverno policy tests

Run from repository root (after patching `<ACR_NAME>` in cluster policies to match test fixtures):

```bash
cd policies/tests
kyverno test kyverno-test.yaml
```

Test fixtures use `acrboutiquedevgwc` — align with your `terraform.tfvars` or update resource YAML.

Signature verification policy (`02-verify-image-signatures.yaml`) is validated manually after Topic 09.
SBOM attestation policy (`05-verify-sbom-attestation.yaml`) starts in **Audit**; Enforce + live verify after Topic 17 pipeline re-run — not covered by CLI unit tests yet.
