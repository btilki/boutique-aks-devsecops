# Data flows

## Application request flow

```mermaid
sequenceDiagram
    participant User
    participant DNS as Azure DNS
    participant NGINX as NGINX Ingress
    participant FE as frontend
    participant SVC as Backend Services
    participant Redis as redis-cart

    User->>DNS: Resolve dev-boutique.biroltilki.art
    DNS-->>User: Ingress public IP
    User->>NGINX: HTTPS GET /
    NGINX->>FE: Route by Host header
    FE->>SVC: gRPC/HTTP internal
    SVC->>Redis: cart persistence
    SVC-->>FE: response
    FE-->>NGINX: HTML
    NGINX-->>User: HTTPS 200
```

**Prose:** External traffic terminates TLS at NGINX. The frontend proxies to internal ClusterIP services. Only the frontend is exposed via Ingress per environment.

## GitOps and supply chain flow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant ADO as Azure DevOps
    participant GAR as Google Registry
    participant ACR as Azure ACR
    participant Git as GitOps Repo
    participant Argo as Argo CD
    participant Kyv as Kyverno
    participant Pod as Pod

    Dev->>ADO: Run mirror pipeline
    ADO->>GAR: Pull image:v0.10.5
    ADO->>ACR: Push retagged image
    ADO->>ADO: Trivy scan @digest
    ADO->>ADO: cosign sign @digest
    ADO->>Git: Update Kustomize digest (dev)
    Argo->>Git: Poll
    Argo->>Pod: Apply manifest
    Kyv->>Pod: Verify signature + policies
    Pod->>ACR: Pull @digest
```

**Order rule:** Scan before sign; sign the same digest that was scanned.

## Telemetry flow

```mermaid
flowchart LR
    APP[Boutique pods] -->|metrics| PROM[Prometheus]
    APP -->|logs| PROMTAIL[Promtail]
    APP -->|OTLP| OTEL[OTel Collector]
    PROMTAIL --> LOKI[Loki]
    OTEL --> PROM
    PROM --> GRAF[Grafana]
    LOKI --> GRAF
    PROM --> AM[Alertmanager]
```

## Secrets flow

```mermaid
flowchart LR
    KV[Key Vault] -->|CSI + WI| POD[Pods]
    KV -->|OIDC read| ADO[ADO cosign key]
    GIT[Git] -.->|never stores secrets| X[—]
```

Git stores only SecretProviderClass references and non-secret configuration.

## Infrastructure flow

`terraform plan/apply` → Azure Resource Manager → resources; state persisted to Azure Storage blob with locking.
