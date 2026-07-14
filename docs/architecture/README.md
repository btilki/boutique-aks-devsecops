# Architecture documentation index

Executive summary: [../../ARCHITECTURE.md](../../ARCHITECTURE.md)

| # | Document | Purpose |
|---|----------|---------|
| 01 | [01-requirements.md](01-requirements.md) | FR/NFR traceability and derived requirements |
| 02 | [02-system-context.md](02-system-context.md) | Actors, external systems, context diagram |
| 03 | [03-component-design.md](03-component-design.md) | In-cluster components and scalability |
| 04 | [04-data-flows.md](04-data-flows.md) | Request, GitOps, telemetry, secrets flows |
| 05 | [05-deployment-flow.md](05-deployment-flow.md) | CI/CD, promotion, rollback |
| 06 | [06-network-design.md](06-network-design.md) | VNet, ingress, DNS, ports |
| 07 | [07-security-architecture.md](07-security-architecture.md) | Trust zones, IAM, supply chain |
| 08 | [08-resilience-and-dr.md](08-resilience-and-dr.md) | Failure scenarios, backup, rebuild |
| 09 | [09-repository-layout.md](09-repository-layout.md) | Approved repo structure and timing tags |
| 10 | [10-observability.md](10-observability.md) | Metrics, logs, traces, alerts |
| 11 | [11-cost-model.md](11-cost-model.md) | Cost estimates and guardrails |

## Maturity statement

This design targets **production pilot** quality: real security controls and operability patterns on a **single** AKS cluster. It does not claim multi-region HA or enterprise-scale DR.
