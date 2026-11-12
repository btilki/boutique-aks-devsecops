# Documentation — boutique-aks-devsecops

Production pilot closed. The delivery path was validated, then Azure resources from the pilot were destroyed. These docs describe what was built and how to rebuild it.

If this file disagrees with [`setup/`](setup/README.md) on bootstrap steps, the setup guide wins.

---

## Where to start

| I want to… | Read |
|------------|------|
| Understand the project quickly | [`../ARCHITECTURE.md`](../ARCHITECTURE.md) · [ADR-0005](adr/0005-cosign-key-based-signing.md) |
| See pilot proof | [`pilot-claims.md`](pilot-claims.md) · [`../assets/images/README.md`](../assets/images/README.md) |
| Review design and delivery | [`architecture/`](architecture/README.md) · [`ci.md`](ci.md) · [`promotion.md`](promotion.md) · [`rollback.md`](rollback.md) · [`security/threat-model.md`](security/threat-model.md) |
| Rebuild or operate | [`setup/`](setup/README.md) (Topics 00–13) · [`../versions.yaml`](../versions.yaml) · [`runbooks/`](runbooks/README.md) |

---

## Guides by topic

| Topic | Entry |
|-------|--------|
| Architecture summary | [`../ARCHITECTURE.md`](../ARCHITECTURE.md) |
| Architecture deep dive | [`architecture/README.md`](architecture/README.md) |
| Design decisions | [`adr/`](adr/README.md) |
| Pilot claims | [`pilot-claims.md`](pilot-claims.md) |
| Bootstrap & teardown | [`setup/README.md`](setup/README.md) |
| Version pins | [`../versions.yaml`](../versions.yaml) |
| Supply-chain CI | [`ci.md`](ci.md) · [`../pipelines/README.md`](../pipelines/README.md) · [setup/09](setup/09-ci-pipeline.md) |
| Promotion / rollback | [`promotion.md`](promotion.md) · [`rollback.md`](rollback.md) · [setup/12](setup/12-promotion-stage-prod.md) · [operations/03](operations/03-rollback.md) |
| Security & threat model | [`security/README.md`](security/README.md) |
| Day-2 operations | [`operations/README.md`](operations/README.md) |
| Symptom troubleshooting | [`troubleshooting/README.md`](troubleshooting/README.md) |
| SLOs | [`slo/README.md`](slo/README.md) |
| Implementation / phases (maintainer) | [`implementation/plan.md`](implementation/plan.md) · [`../ROADMAP.md`](../ROADMAP.md) |
| Cost model | [`architecture/11-cost-model.md`](architecture/11-cost-model.md) |

---

## Hostnames (when rebuilt)

| Service | FQDN |
|---------|------|
| Argo CD | `argocd-boutique.biroltilki.art` |
| Grafana | `grafana-boutique.biroltilki.art` |
| Boutique dev | `dev-boutique.biroltilki.art` |
| Boutique stage | `stage-boutique.biroltilki.art` |
| Boutique prod | `boutique.biroltilki.art` |

---

## Repository meta

| File | Purpose |
|------|---------|
| [`../README.md`](../README.md) | Project landing page |
| [`../CONTRIBUTING.md`](../CONTRIBUTING.md) | How to contribute |
| [`../SECURITY.md`](../SECURITY.md) | Security reporting |
| [`../CHANGELOG.md`](../CHANGELOG.md) | Notable changes |

Sister platforms (same author): [boutique-eks-gitops](https://github.com/btilki/boutique-eks-gitops) · [boutique-gke-sre](https://github.com/btilki/boutique-gke-sre)

Maintainer planning (not a reader path): [`implementation/plan.md`](implementation/plan.md) · [`implementation/phase15-plus.md`](implementation/phase15-plus.md) · optional setup guides 14–20 after rebuild
