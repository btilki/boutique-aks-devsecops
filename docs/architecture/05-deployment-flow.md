# Deployment flow

How images move from mirror to overlays and how Argo syncs each environment. Prod stays behind human gates.

## Promotion path

```mermaid
flowchart TD
    A[Mirror v0.10.5 to ACR] --> B[Trivy CRITICAL gate]
    B --> C["cosign sign --tlog-upload=false"]
    C --> D[Update dev overlay digest]
    D --> E[Argo auto-sync dev]
    E --> F{Dev smoke OK?}
    F -->|yes| G[Update stage overlay same digest]
    G --> H[Manual Argo sync stage]
    H --> I{Stage OK?}
    I -->|yes| J[ADO Environment Approval PROD]
    J --> K[Update prod overlay same digest]
    K --> L[Manual Argo sync prod]
    F -->|no| R[Fix pipeline / image]
    I -->|no| R
    J -->|rejected| X[Stop — no prod change]
```

## CI pipeline stages (ADO)

| Stage | Actions | Repo |
|-------|---------|------|
| Mirror | Pull GAR → push ACR per service | `pipelines/azure-pipelines.yml` |
| Scan | `trivy image --severity CRITICAL --exit-code 1 @digest` | `templates/build-scan-sign.yml` |
| Sign | `cosign sign --key ... --tlog-upload=false @digest` | same |
| Promote-dev | Commit digest to `overlays/dev` | pipeline or manual PR |
| Promote-stage/prod | Update overlays; prod requires ADO approval | `templates/promote-digest.yml` |

## GitOps model

**ADO commits digest pins to Git; Argo CD applies cluster state** — pipelines do not kubectl apply to prod.

- Root app → platform apps + boutique apps
- Sync waves: CRDs → cert-manager → ingress → kyverno → policies → applications
- Health: Argo CD + frontend `/_healthz` endpoint

## Rollback

| Layer | Mechanism |
|-------|-----------|
| Application | Git revert digest in overlay; manual Argo sync |
| Platform | Argo CD history rollback |
| Infrastructure | Terraform state revert + apply |

Phase 14 **destroys ACR**. Rollback to a prior digest only works if that image still exists in ACR; otherwise re-run the mirror pipeline.

## Human gates

| Gate | Mechanism |
|------|-----------|
| Stage deploy | Manual Argo sync |
| Prod deploy | **ADO environment approval** + manual Argo sync |
| Policy enforcement | Kyverno `failurePolicy: Fail` |
