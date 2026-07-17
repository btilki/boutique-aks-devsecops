# Requirements

## Functional requirements

| ID | Requirement | Priority | Phase | Repo path |
|----|-------------|----------|-------|-----------|
| FR-01 | Terraform: RG, remote state, VNet, AKS subnet, NSGs, Azure DNS `biroltilki.art` | Must | 1–2 | `terraform/` |
| FR-02 | AKS + WI, ACR, Key Vault, Entra RBAC, kubelet AcrPull, ADO OIDC | Must | 3–4 | `terraform/modules/` |
| FR-03 | GitOps platform: Argo CD, NGINX, cert-manager, CSI, Kyverno, monitoring | Must | 5–8, 11 | `gitops/platform/` |
| FR-04 | ADO: mirror, Trivy gate, cosign sign, digest GitOps promotion | Must | 9–12 | `pipelines/` |

## Non-functional requirements

| Category | Requirement | Architecture response |
|----------|-------------|----------------------|
| Availability | Production-minimum single cluster | Namespace isolation; documented rollback |
| Security | Least privilege; signed images; no secrets in Git | OIDC, KV CSI, Kyverno |
| Observability | Metrics, dashboards, alerts, SLO | kube-prometheus-stack, OTel |
| Maintainability | Modular IaC and GitOps | TF modules; Kustomize overlays |
| Cost | Solo test budget | One cluster; teardown destroys ACR |
| Reproducibility | Pinned versions | `versions.yaml` |

## Derived requirements

| ID | Requirement | Source |
|----|-------------|--------|
| DR-01 | Mirror all v0.10.5 images to ACR and sign | Kyverno ACR allowlist |
| DR-02 | Patch `busybox:latest` and `redis:alpine` in overlays | Kyverno deny `:latest` |
| DR-03 | Azure DNS NS delegation before TLS | cert-manager DNS-01 |
| DR-04 | Prod promotion via ADO environment approval only | Project decision |
| DR-05 | Digest-pinned images in overlays | Immutable GitOps |

## Online Boutique v0.10.5

| Field | Value |
|-------|-------|
| Upstream | `GoogleCloudPlatform/microservices-demo` tag `v0.10.5` |
| Source registry | `us-central1-docker.pkg.dev/google-samples/microservices-demo` |
| Services | 11 microservices + redis-cart + loadgenerator |
| Packaging | Kustomize base + env overlays |

Policy exceptions required for upstream `busybox:latest` (loadgenerator init) and `redis:alpine` — replaced with pinned ACR copies in overlays.
