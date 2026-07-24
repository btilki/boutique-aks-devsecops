# Roadmap — boutique-aks-devsecops

**Status:** Setup Topics **00–13** complete. Azure test torn down (reference repo + screenshots retained). **Phase 15+** fuller DevSecOps work in progress (scaffold-first — [ADR-0013](docs/adr/0013-scaffold-first-phase15.md)).
**Numbering note:** Setup **Topic 13** = teardown (`docs/setup/13-teardown.md`). Roadmap **Phase 13** = hardening/integration (skipped; superseded by Phase 15+). **Phase 14** = teardown. Setup Topics **14–20** = Phase 15+ apply guides (scaffold packages 2–8).
**Detailed plan:** [docs/implementation/plan.md](docs/implementation/plan.md) · [docs/implementation/phase15-plus.md](docs/implementation/phase15-plus.md)
**Architecture:** [ARCHITECTURE.md](ARCHITECTURE.md)

## Vision

Build a production-style reference platform that proves secure delivery end-to-end: Terraform foundation → GitOps platform services → signed digest promotion → Kyverno enforcement → observability and runbooks — on one AKS cluster in **Germany West Central**. Phase 15+ deepens shift-left CI, network isolation, SBOM/attestations, runtime detection, and namespace/KV hardening — **scaffolded in-repo first**, applied when Azure is rebuilt.

## Milestones

| Milestone | Phases | Definition of done | Status |
|-----------|--------|-------------------|--------|
| M1: Repo & state ready | 0–1 | Pre-commit passes; remote TF state exists | ✅ |
| M2: Azure foundation live | 2–3 | AKS Ready; ACR + Key Vault reachable | ✅ |
| M3: Trust & GitOps | 4–5 | ADO OIDC works; Argo CD healthy | ✅ |
| M4: Platform services | 6–8 | TLS Ready; Kyverno enforces | ✅ |
| M5: Secure delivery | 9–10 | Signed v0.10.5 images; dev app live | ✅ |
| M6: Operate & promote | 11–12 | Grafana + SLO; stage/prod promotion | ✅ |
| M7: Complete & teardown | 13–14 | Smoke tests pass; teardown validated | ✅ |
| M8a: Phase 15+ plan | 15 | Inventory + ADR-0013; packages 2–8 defined | ✅ |
| M8b: Shift-left CI | 16, 18 | PR pipeline + IaC scan scaffolded | ✅ |
| M8c: Cluster hardening | 17, 21 | NetworkPolicies + PSA/KV ACL scaffolded | ✅ |
| M8d: Supply chain depth | 19 | SBOM + attestations scaffolded | ✅ |
| M8e: Runtime + DAST | 20, 22 | Falco/Defender + optional DAST scaffolded | ✅ |

## Phase overview

### Lived pilot — Topics 00–13 (complete)

| Phase | Title | Status | Setup topic | Key validation |
|-------|-------|--------|-------------|----------------|
| 0 | Repository scaffold | ✅ | 00-prerequisites | `pre-commit run --all-files` (run locally) |
| 1 | Terraform bootstrap | ✅ | 01-terraform-bootstrap | State container exists |
| 2 | Azure foundation | ✅ | 02-azure-foundation | DNS zone + VNet in portal |
| 3 | AKS, ACR, Key Vault | ✅ | 03-cluster-resources | `kubectl get nodes` |
| 4 | ADO OIDC federation | ✅ | 04-ado-oidc | OIDC test pipeline green |
| 5 | GitOps bootstrap | ✅ | 05-gitops-bootstrap | Argo CD @ argocd-boutique |
| 6 | Ingress + TLS | ✅ | 06-ingress-tls | Certificate Ready |
| 7 | Secrets Store CSI | ✅ | 07-secrets-csi | KV secret mounted |
| 8 | Kyverno + policies | ✅ | 08-admission-policies | Unsigned image denied |
| 9 | CI mirror, scan, sign | ✅ | 09-ci-pipeline | Signed digest in ACR |
| 10 | Boutique dev deploy | ✅ | 10-boutique-dev | dev-boutique reachable |
| 11 | Observability | ✅ | 11-observability | Grafana dashboard loads |
| 12 | Stage/prod promotion | ✅ | 12-promotion-stage-prod | Same digest in prod |
| 13 | Hardening & integration | ⏭️ | — | Superseded by Phase 15+; smokes ran in Topics 10–12 |
| 14 | Teardown | ✅ | 13-teardown | No billable AKS/ACR |

### Phase 15+ — Fuller DevSecOps (scaffold-first)

| Phase | Title | Scaffold | Setup topic (future) | Package | Apply-later validation |
|-------|-------|----------|----------------------|---------|------------------------|
| 15 | Backlog & plan | ✅ | [phase15-plus.md](docs/implementation/phase15-plus.md) | 1 | N/A (docs only) |
| 16 | PR CI gates | ✅ | [14-pr-ci](docs/setup/14-pr-ci.md) | 2 | PR pipeline green on sample PR |
| 17 | NetworkPolicies | ✅ | [15-network-policies](docs/setup/15-network-policies.md) | 3 | Default-deny + Boutique paths enforce |
| 18 | IaC scanning | ✅ | [16-iac-scanning](docs/setup/16-iac-scanning.md) | 4 | Checkov fails on introduced misconfig |
| 19 | SBOM + attestations | ✅ | [17-sbom-attestations](docs/setup/17-sbom-attestations.md) | 5 | Attestation present; policy documents verify path |
| 20 | Runtime security | ✅ | [18-runtime-security](docs/setup/18-runtime-security.md) | 6 | Falco/Defender workloads Ready |
| 21 | KV ACL + PSA/quotas | ✅ | [19-namespace-hardening](docs/setup/19-namespace-hardening.md) | 7 | ACL + PSA/quota objects applied |
| 22 | DAST (optional) | ✅ | [20-dast](docs/setup/20-dast.md) | 8 | ZAP baseline job completes |

Status: ⬜ not started · 🔄 in progress · ✅ complete · ⏭️ skipped
**Scaffold ✅** means files + setup topic exist in Git. **Live apply** is a separate checklist inside each Topic 14–20.

## Incremental value

| After phase | You can… |
|-------------|----------|
| 0 | Use a documented, linted repo skeleton |
| 1 | Run Terraform with remote Azure state |
| 2 | See VNet, NSG, and Azure DNS zone in subscription |
| 3 | `kubectl get nodes`; push to ACR |
| 4 | ADO pipeline auth without long-lived secrets |
| 5 | Open Argo CD and sync platform apps |
| 6 | Hit HTTPS endpoints with Let's Encrypt certs |
| 7 | Mount Key Vault secrets via CSI |
| 8 | Block unsigned / `:latest` / non-ACR images |
| 9 | Mirror, scan, and sign Boutique v0.10.5 |
| 10 | Shop on dev-boutique.biroltilki.art |
| 11 | View metrics/dashboards; test an alert |
| 12 | Promote one digest dev → stage → prod |
| 13 | _(skipped — see Phase 15+)_ |
| 14 | Tear down test resources; ACR destroyed |
| 15 | Follow a package backlog for fuller DevSecOps without Azure |
| 16 | Fail PRs on lint / TF validate / Kyverno unit tests |
| 17 | Limit east-west traffic between Boutique services |
| 18 | Catch Terraform misconfigs in CI |
| 19 | Attach SBOM/attestations to mirrored digests |
| 20 | Detect suspicious runtime behavior |
| 21 | Tighten KV exposure and namespace blast radius |
| 22 | Run optional DAST against the storefront |

## Out of scope (still deferred)

- Multi-region DR
- Service mesh ([ADR-0007](docs/adr/0007-no-service-mesh.md))
- Azure Policy duplicate of Kyverno
- Private AKS / private ACR (optional stretch notes only)
- WAF / Front Door / DDoS
- Build-from-source SAST on Boutique app code (mirror model remains default)
- HSM-backed cosign keys

Trivy vuln **cosign attestations** (vuln predicate) remain a stretch; **SPDX SBOM attestations** are Phase 19 / Topic 17 ([ADR-0014](docs/adr/0014-sbom-cosign-attestations.md)).
