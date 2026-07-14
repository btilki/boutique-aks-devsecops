# Repository layout

Variant **A (Full platform)** adapted for Azure DevOps and approved naming.

## Top-level domains

| Directory | Domain |
|-----------|--------|
| `terraform/` | Cloud provisioning (Azure) |
| `gitops/` | Declarative cluster state (Argo CD) |
| `policies/` | Admission enforcement (Kyverno) |
| `pipelines/` | CI/CD (Azure DevOps) |
| `docs/` | Architecture, setup, security, operations |
| `scripts/` | Guarded operational helpers |
| `tests/` | Validation and smoke tests |
| `examples/` | Isolated demos |

## Environment promotion

- **Terraform:** single root `terraform/environments/dev/` (physical platform)
- **Kubernetes:** Kustomize overlays `gitops/apps/boutique/overlays/{dev,stage,prod}`
- **Images:** digest promotion via `pipelines/` → Git commit

## Timing tags

- **SETUP_REQUIRED** — must exist before/during setup topic (Phase B authoring)
- **FEATURE_REQUIRED** — created during feature phase
- **RELEASE_REQUIRED** — before declaring milestone complete

See [implementation plan](../implementation/plan.md).
