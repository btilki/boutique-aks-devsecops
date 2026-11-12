# Architecture deep dive — boutique-aks-devsecops

Production pilot closed. Azure resources from the pilot were destroyed.
These pages describe the design as it exists in Git. They do not provision Azure.

If you skipped the summary, start here: [`../../ARCHITECTURE.md`](../../ARCHITECTURE.md) (executive summary, diagrams, tradeoffs).

---

## How to use this folder

| I want to… | Read first |
|------------|------------|
| Follow CI → Git → Argo → prod | [05-deployment-flow.md](05-deployment-flow.md) |
| Understand security (identity, Kyverno, secrets, supply chain) | [07-security-architecture.md](07-security-architecture.md) |
| See metrics, logs, alerts | [10-observability.md](10-observability.md) |
| Judge cost and teardown | [11-cost-model.md](11-cost-model.md) |
| Walk requirements and constraints | [01-requirements.md](01-requirements.md) |
| Network and ingress | [06-network-design.md](06-network-design.md) |

Pilot claims (no cluster required): [`../pilot-claims.md`](../pilot-claims.md)
Delivery contracts: [`../ci.md`](../ci.md) · [`../promotion.md`](../promotion.md) · [`../rollback.md`](../rollback.md)

---

## Architecture pages

| Doc | Purpose |
|-----|---------|
| [01-requirements.md](01-requirements.md) | FRs, NFRs, constraints, assumptions |
| [02-system-context.md](02-system-context.md) | Context, actors, environment strategy |
| [03-component-design.md](03-component-design.md) | Component inventory + diagram |
| [04-data-flows.md](04-data-flows.md) | App, GitOps, secrets, telemetry |
| [05-deployment-flow.md](05-deployment-flow.md) | CI, promotion, sync, rollback |
| [06-network-design.md](06-network-design.md) | VNet, ingress, DNS, ports |
| [07-security-architecture.md](07-security-architecture.md) | Trust zones, Workload Identity, supply chain |
| [08-resilience-and-dr.md](08-resilience-and-dr.md) | Failures, scale, DR, rebuild |
| [09-repository-layout.md](09-repository-layout.md) | Repo structure and timing tags |
| [10-observability.md](10-observability.md) | Metrics, logs, alerts |
| [11-cost-model.md](11-cost-model.md) | Cost drivers, guardrails, teardown |

---

## Architecture Decision Records

| ADR | Decision |
|-----|----------|
| [ADR-0001](../adr/0001-azure-cloud-provider.md) | Azure as sole cloud |
| [ADR-0002](../adr/0002-single-cluster-multi-namespace.md) | Single AKS; three namespace environments |
| [ADR-0003](../adr/0003-kyverno-admission.md) | Kyverno admission |
| [ADR-0004](../adr/0004-argocd-gitops.md) | Argo CD GitOps |
| [ADR-0005](../adr/0005-cosign-key-based-signing.md) | Key-based cosign; transparency log off |
| [ADR-0006](../adr/0006-kustomize-boutique.md) | Kustomize for Boutique |
| [ADR-0007](../adr/0007-no-service-mesh.md) | No service mesh in v1 |
| [ADR-0008](../adr/0008-ado-prod-approval-gate.md) | ADO environment approval for prod |
| [ADR-0009](../adr/0009-mirror-upstream-images.md) | Mirror upstream v0.10.5 images |
| [ADR-0010](../adr/0010-destroy-acr-on-teardown.md) | Destroy ACR on teardown |
| [ADR-0011](../adr/0011-aks-node-vm-sku.md) | Node VM SKUs and region |
| [ADR-0012](../adr/0012-loki-in-cluster-logging.md) | In-cluster Loki instead of Log Analytics |
| [ADR-0013](../adr/0013-scaffold-first-phase15.md) | Deferred hardening inventory (apply after rebuild) |
| [ADR-0014](../adr/0014-sbom-cosign-attestations.md) | SPDX SBOM + cosign attestations |
| [ADR-0015](../adr/0015-falco-runtime-detection.md) | Falco runtime detection |
| [ADR-0016](../adr/0016-namespace-kv-hardening.md) | Namespace PSA / quotas; optional KV ACL |
| [ADR-0017](../adr/0017-optional-zap-dast.md) | Optional ZAP baseline DAST |

Full ADR index: [`../adr/README.md`](../adr/README.md)

---

## Maturity

This is a **production pilot**: real security controls and day-2 patterns on one AKS cluster. It does not claim multi-region HA or enterprise-scale DR.

---

## Related

- [`../README.md`](../README.md) — documentation index
- [`../implementation/plan.md`](../implementation/plan.md) — phase detail (maintainer reference)
- [`../../ROADMAP.md`](../../ROADMAP.md) — milestones and phase status
- [`../setup/README.md`](../setup/README.md) — rebuild (Topics 00–13)
- [`../../versions.yaml`](../../versions.yaml) — version pins
