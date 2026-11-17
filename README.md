# boutique-aks-devsecops

Production reference Azure DevSecOps for Online Boutique on AKS — signed digests, Kyverno admission, GitOps promotion.

> **Status:** Production reference closed. Setup Topics **00–13** ran end to end; then the Azure resources were destroyed. There is no live AKS, ACR, or Key Vault from that run. To run again, follow [`docs/setup/`](docs/setup/).

---

## Problem

Mutable tags and unsigned images make “what is running?” hard to trust. Long-lived CI secrets and a pipeline that can push straight into the cluster create a second deploy authority next to Git. A demo that only shows Terraform apply does not prove the supply-chain path.

## Decision

- **Mirror, scan, sign, promote by digest** — Azure DevOps mirrors Boutique into ACR, fails on CRITICAL findings, cosign-signs digests, then updates GitOps overlays ([ADR-0005](docs/adr/0005-cosign-key-based-signing.md)).
- **Admission blocks the easy mistakes** — Kyverno allows only ACR, denies `:latest`, and verifies signatures on Boutique workloads.
- **Git is what Argo CD reconciles** — GitHub holds desired state; ADO uses OIDC to Azure (no long-lived pipeline secrets). Prod promotion needs an ADO environment approval.
- **One AKS cluster, three namespaces** — cost over blast-radius isolation.

## Result

Setup Topics **00–13** ran end to end, then the platform was torn down. The lived path covered Terraform foundation, ADO OIDC, Argo CD and platform services, Kyverno Enforce on Boutique, mirror → Trivy → cosign → digest promotion, Grafana and Loki, and ordered destroy. While active, cost was roughly €150–250/month. Teardown destroys ACR, so a rebuild must re-mirror. Claims: [`docs/reference-claims.md`](docs/reference-claims.md).

---

## At a glance

| | |
|-|-|
| What | DevSecOps on one AKS cluster in `germanywestcentral` |
| App pin | Online Boutique — see [`versions.yaml`](versions.yaml) |
| Hard rule | **Unsigned or floating tags should not reach the cluster** |
| CI model | GitHub = source of truth · Azure DevOps = pipelines (OIDC) · no GitHub Actions |
| Scope | Production reference — one subscription, one region; not multi-region HA |
| Topics 14–20 | Scaffold in Git only — not lived proof unless rebuilt and applied ([`reference-claims`](docs/reference-claims.md)) |
| Stack | Terraform · AKS · ACR · Key Vault · Argo CD · Kyverno · Trivy · cosign · Prometheus / Loki / Grafana |

---

## Proof

Screenshots from the lived run (hostnames offline until rebuild). Full catalog: [`assets/images/README.md`](assets/images/README.md).

**Argo CD** — filtered Synced + Healthy view from the lived run (apps shown still match GitOps Application CRs; Falco stays opt-in):

![Argo CD applications healthy](assets/images/setup/05-argocd-applications-healthy.png)

**Azure DevOps** — supply-chain pipeline green (mirror → Trivy → cosign):

![ADO supply-chain pipeline success](assets/images/setup/09-ado-pipeline-supply-chain-success.png)

**Storefront** — `dev-boutique.biroltilki.art` over HTTPS (when live):

![Boutique dev homepage](assets/images/setup/10-dev-boutique-homepage.png)

More: ACR digests, Grafana, stage/prod — [`assets/images/setup/`](assets/images/setup/).

---

## Tradeoffs / what I would change for real production

- **Single cluster, three namespaces** — fine for a cost-capped reference; not true env isolation. Separate clusters (or subscriptions) for prod.
- **Public API server, system pool size 1, no availability zones** — rebuild would tighten API access and HA first.
- **Trivy CRITICAL with `--ignore-status fixed`** — upstream Boutique is mirrored, not rebuilt; fixed CVEs can still appear in the image.
- **Cosign key passphrase empty; transparency log off** — Key Vault RBAC protects the key; a client path would use a passphrase or keyless signing and Rekor.
- **Signature verify skips platform namespaces** — Boutique is gated; platform charts are a second trust domain.

Do **not** call this production-ready. The namespace named `prod` is a promotion stage on the same cluster. Public-share rules: [CONTRIBUTING.md](CONTRIBUTING.md#public-share-hygiene).

---

## Where to start

| I want to… | Read |
|------------|------|
| Understand the project in ~10 minutes | This page → [`ARCHITECTURE.md`](ARCHITECTURE.md) → [ADR-0005](docs/adr/0005-cosign-key-based-signing.md) |
| See reference proof | [`docs/reference-claims.md`](docs/reference-claims.md) · [`assets/images/`](assets/images/README.md) |
| Review design and delivery | [`docs/architecture/`](docs/architecture/README.md) · [`docs/ci.md`](docs/ci.md) · [`docs/promotion.md`](docs/promotion.md) · [`docs/rollback.md`](docs/rollback.md) · [`docs/security/threat-model.md`](docs/security/threat-model.md) |
| Rebuild or operate | [`docs/setup/`](docs/setup/README.md) (Topics 00–13) · [`versions.yaml`](versions.yaml) · [`docs/runbooks/`](docs/runbooks/README.md) |

Full index: [`docs/README.md`](docs/README.md)

---

## Supply-chain flow (summary)

```mermaid
flowchart LR
  ADO[Azure DevOps] -->|OIDC mirror scan sign| ACR[ACR]
  ADO -->|digest commit| Git[(GitHub)]
  Git -->|pull| Argo[Argo CD]
  Argo --> Dev[boutique-dev]
  Argo --> Stage[boutique-stage]
  Argo --> Prod[boutique-prod]
  Users((Users)) -->|HTTPS NGINX + cert-manager| Dev & Stage & Prod
```

Promotion: `dev → stage → prod` (same digest; **ADO approval before prod**). Details: [`docs/architecture/05-deployment-flow.md`](docs/architecture/05-deployment-flow.md).

---

## Repository map and navigation

This map shows repository layout, platform components, and where each engineering area lives.

![Boutique AKS DevSecOps — Repository Map and Navigation](assets/images/aks-devsecops-repository-map.jpg)

---

## Technology stack

| Area | Choices |
|------|---------|
| Cloud / region | Azure `germanywestcentral` |
| IaC | Terraform ≥ 1.6 |
| Kubernetes | AKS, Azure CNI |
| GitOps / delivery | Argo CD, Kustomize overlays |
| Policy / secrets | Kyverno, Secrets Store CSI, Key Vault |
| Ingress / TLS | NGINX Ingress, cert-manager, Let's Encrypt DNS-01 |
| CI / supply chain | Azure DevOps, ACR, Trivy, cosign |
| Observability | kube-prometheus-stack, Loki, Promtail, Grafana |

Pins: [`versions.yaml`](versions.yaml) · Deep design: [`docs/architecture/README.md`](docs/architecture/README.md)

---

## Repository layout

```text
boutique-aks-devsecops/
├── terraform/    # Azure IaC (bootstrap, modules, environments/dev)
├── gitops/       # Argo CD bootstrap, platform, Boutique overlays
├── policies/     # Kyverno cluster policies and tests
├── pipelines/    # Azure DevOps CI (not GitHub Actions)
├── docs/         # Architecture, setup, security, runbooks
├── scripts/      # Guarded helpers (teardown, OIDC verify)
├── tests/        # Terraform, policy, integration validation
└── examples/     # Runnable demos (CSI secret test)
```

---

## Quick clone

```bash
git clone https://github.com/btilki/boutique-aks-devsecops.git
cd boutique-aks-devsecops
```

Do not provision Azure from this file. Bootstrap and destroy live under [`docs/setup/`](docs/setup/).

---

## Contributing · License · References

- Contributing: [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Security: [`SECURITY.md`](SECURITY.md)
- Changelog: [`CHANGELOG.md`](CHANGELOG.md)
- Roadmap: [`ROADMAP.md`](ROADMAP.md)

Licensed under Apache License 2.0 — see [`LICENSE`](LICENSE). Upstream app: [Google Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo).

Stack references: [Argo CD](https://argo-cd.readthedocs.io/) · [Kyverno](https://kyverno.io/) · [cosign](https://docs.sigstore.dev/) · [Trivy](https://trivy.dev/) · [Azure AKS](https://learn.microsoft.com/azure/aks/)
