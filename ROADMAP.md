# Roadmap — boutique-aks-devsecops

**Status:** Setup Topics **00–13** complete. Azure test torn down (reference repo + screenshots retained).
**Numbering note:** Setup **Topic 13** = teardown (`docs/setup/13-teardown.md`). Roadmap **Phase 13** = hardening/integration (no setup guide); **Phase 14** = teardown.
**Detailed plan:** [docs/implementation/plan.md](docs/implementation/plan.md)
**Architecture:** [ARCHITECTURE.md](ARCHITECTURE.md)

## Vision

Build a production-style reference platform that proves secure delivery end-to-end: Terraform foundation → GitOps platform services → signed digest promotion → Kyverno enforcement → observability and runbooks — on one AKS cluster in **Germany West Central**.

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

## Phase overview

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
| 13 | Hardening & integration | ⏭️ | — | Smokes run during Topics 10–12; further hardening deferred |
| 14 | Teardown | ✅ | 13-teardown | No billable AKS/ACR |

Status: ⬜ not started · 🔄 in progress · ✅ complete · ⏭️ skipped

## Incremental value

| After phase | You can… |
|-------------|-----------|
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
| 13 | Hand repo to another engineer with passing smokes |
| 14 | Tear down test resources; ACR destroyed |

## Out of scope (deferred)

- Multi-region DR
- Service mesh
- Trivy vuln cosign attestations (v1)
- Azure Policy duplicate of Kyverno
