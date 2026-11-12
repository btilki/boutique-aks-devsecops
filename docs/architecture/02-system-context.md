# System context

Who touches the platform, which external systems it depends on, and how traffic and supply chain cross the Azure boundary.

## Actors

| Actor | Interactions |
|-------|--------------|
| Platform engineer | Terraform, kubectl, Argo CD, Azure Portal |
| Developer | Git push, ADO pipeline runs |
| Demo user | HTTPS to Boutique hostnames |
| Let's Encrypt | DNS-01 challenges against Azure DNS |
| Google Artifact Registry | Read-only pull for mirror pipeline |

## External dependencies

| System | Purpose | Failure impact |
|--------|---------|----------------|
| Azure subscription | Hosts all infrastructure | Total outage |
| Domain registrar | NS delegation to Azure DNS | TLS issuance blocked |
| Azure DevOps | CI/CD, prod approval gate | No new images/promotions |
| Google sample images | Boutique v0.10.5 source | Mirror pipeline blocked |

## Context diagram

```mermaid
graph TB
    subgraph Users
        ENG[Platform Engineer]
        DEV[Developer]
        SHOP[Demo User]
    end

    subgraph External
        GIT[Git Repository]
        ADO[Azure DevOps]
        LE[Let's Encrypt]
        GAR[Google Artifact Registry]
        REG[Domain Registrar]
    end

    subgraph Azure["Azure Subscription — germanywestcentral"]
        TF[Terraform State]
        subgraph Platform["boutique-aks-devsecops"]
            AKS[AKS Cluster]
            ACR[Azure Container Registry]
            KV[Key Vault]
            DNS[Azure DNS biroltilki.art]
            LOKI[Loki in-cluster]
        end
    end

    ENG --> TF
    ENG --> AKS
    ENG --> ADO
    DEV --> GIT
    DEV --> ADO
    ADO -->|OIDC| ACR
    ADO -->|OIDC| KV
    ADO -->|mirror| GAR
    GIT -->|GitOps| AKS
    SHOP -->|HTTPS| AKS
    LE -->|DNS-01| DNS
    REG -->|NS| DNS
    AKS --> ACR
    AKS --> KV
    AKS --> DNS
    AKS --> LOKI
```

The platform runs in one Azure region. Git holds desired state; ADO builds, signs, and promotes; Google public images are upstream only until mirrored. The registrar delegates DNS. Runtime pulls never hit Google — only signed images from ACR after mirror/sign.
