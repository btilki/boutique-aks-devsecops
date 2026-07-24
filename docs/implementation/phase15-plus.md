# Phase 15+ — Fuller DevSecOps (scaffold-first)

**Status:** Packages **1–8** complete — Phase 15+ fuller DevSecOps scaffold finished. Live apply awaits Azure rebuild (Topics 14–20).

**Mode:** **Scaffold only** — author files and setup topics for future apply. Do **not** require a live Azure cluster, Terraform apply, or re-run of Setup Topics 00–13.
**Roadmap:** [ROADMAP.md](../../ROADMAP.md)
**Parent plan:** [plan.md](plan.md)
**ADR:** [ADR-0013](../adr/0013-scaffold-first-phase15.md)

---

## 1. Purpose

Extend the lived pilot (Topics 00–13) with additional DevSecOps controls that were deferred or skipped (especially Roadmap **Phase 13** hardening).

| Mode | What | Azure required? |
|------|------|-----------------|
| **Scaffold** (now) | Pipelines, policies, GitOps stubs, TF stubs, setup topics, ADRs | No |
| **Apply later** | Rebuild Topics 00–12 (or equivalent), then execute Topics 14+ | Yes |

**Success for scaffold:** another engineer can open each future setup topic and know exactly which files to create/edit and which validation commands to run when the platform is live again.

---

## 2. Relationship to Phase 13

Roadmap **Phase 13** (hardening & integration) was **skipped** (⏭️) during the pilot. Phase **15+** **supersedes** that deferred backlog — do not reopen Phase 13 as a live workstream.

Items absorbed from [docs/operations/20-automation-opportunities.md](../operations/20-automation-opportunities.md) and Phase 13 intent:

- ADO PR pipeline
- NetworkPolicies for `boutique-*`
- KV network ACL
- (plus new fuller-DevSecOps items: IaC scan, SBOM/attestations, runtime security, PSA/quotas, DAST)

---

## 3. Goals (G-07+)

| ID | Goal | Success indicator (after apply) |
|----|------|----------------------------------|
| G-07 | PR-time quality/security gates | ADO PR pipeline fails on lint / TF validate / Kyverno test |
| G-08 | East-west isolation | Default-deny NetworkPolicies; Boutique graph allows only needed paths |
| G-09 | IaC security scanning | Checkov (or tfsec) blocks CRITICAL misconfigs on PRs |
| G-10 | SBOM + attestations | SBOM artifact + cosign attestation; Kyverno can require attestation |
| G-11 | Runtime detection | Falco (and/or Defender for Containers) deployed via GitOps/TF |
| G-12 | Namespace / KV hardening | PSA labels, quotas; KV network ACL documented and applied |
| G-13 | Optional DAST | ZAP baseline job against `dev-boutique` (non-blocking or gated) |

---

## 4. Functional requirements (FR-05+)

| ID | Requirement | Phase |
|----|-------------|-------|
| FR-05 | ADO PR pipeline: pre-commit-equivalent + TF validate + `kyverno test` | 16 |
| FR-06 | NetworkPolicies for boutique service graph (dev/stage/prod) | 17 |
| FR-07 | IaC scanner in CI on `terraform/` | 18 |
| FR-08 | SBOM generation + cosign attestation; policy stub for verify | 19 |
| FR-09 | Runtime security component (Falco and/or Defender) | 20 |
| FR-10 | KV network ACL + namespace PSA / ResourceQuota / LimitRange | 21 |
| FR-11 | Optional DAST pipeline template against storefront | 22 |

---

## 5. Constraints (unchanged unless ADR says otherwise)

- Azure only; single AKS; logical envs as namespaces
- GitHub = VCS; Azure DevOps = CI/CD (no GitHub Actions)
- No secrets in Git; OIDC for pipeline Azure access
- Prefer mirror-not-rebuild for Boutique images (ADR-0009) unless a later ADR changes it
- No service mesh in this scope (ADR-0007)
- Scaffold packages must not invent live credentials or commit private keys

---

## 6. Scaffold packages (work order)

Execute **one package per session**. Each package delivers files + setup topic + ROADMAP status bump.

| Package | Phase | Title | Future setup topic | Primary paths (expected) | Status |
|---------|-------|-------|--------------------|--------------------------|--------|
| **1** | 15 | Backlog & plan | _(this doc)_ | `ROADMAP.md`, `docs/implementation/*`, ADR-0013 | ✅ |
| **2** | 16 | PR CI gates | [14-pr-ci.md](../setup/14-pr-ci.md) | `pipelines/azure-pipelines-pr.yml`, `templates/pr-*.yml`, `tests/ci/pr-validate.sh` | ✅ |
| **3** | 17 | NetworkPolicies | [15-network-policies.md](../setup/15-network-policies.md) | `gitops/apps/boutique/base/networkpolicies/`, `aks_network_policy` TF | ✅ |
| **4** | 18 | IaC scanning | [16-iac-scanning.md](../setup/16-iac-scanning.md) | `tests/terraform/.checkov.yaml`, `checkov.sh`, PR Checkov job | ✅ |
| **5** | 19 | SBOM + attestations | [17-sbom-attestations.md](../setup/17-sbom-attestations.md) | `build-scan-sign.yml`, `05-verify-sbom-attestation.yaml`, ADR-0014 | ✅ |
| **6** | 20 | Runtime security | [18-runtime-security.md](../setup/18-runtime-security.md) | `gitops/platform/falco/`, ADR-0015, Defender opt-in note | ✅ |
| **7** | 21 | KV ACL + PSA/quotas | [19-namespace-hardening.md](../setup/19-namespace-hardening.md) | `base/hardening/`, PSA labels, KV ACL/purge vars, ADR-0016 | ✅ |
| **8** | 22 | DAST (optional) | [20-dast.md](../setup/20-dast.md) | `pipelines/azure-pipelines-dast.yml`, ADR-0017 | ✅ |

**Numbering note:** Setup **Topic 13** remains teardown. New guides are Topics **14–20**. Roadmap phases **15–22** map to those topics (Phase 15 = planning only).

---

## 7. Per-package deliverable checklist

Every package (2–8) must include:

1. **Files** — real YAML/HCL/templates (stubs allowed where live values are unknown; mark `REPLACE_ME` / placeholders)
2. **Setup topic** — same structure as Topics 00–13 (Purpose, When to use, Prerequisites, Steps, Validation, Rollback)
3. **Apply later** section — commands that need AKS/ADO/ACR, explicitly labeled
4. **Deferred validation** — what cannot be proven until rebuild
5. **ROADMAP** — flip package/phase status from ⬜ → ✅ (scaffold) ; apply status tracked separately if needed
6. **ADR** — only when a new decision is required (e.g. Falco vs Defender, attestation predicate type)

---

## 8. Apply-later protocol (after Azure rebuild)

When you rebuild the platform:

1. Complete Setup Topics **00–12** (or restore from docs) until Boutique + CI + Kyverno work again
2. Execute Topics **14–20** in order (skip 20/DAST if optional)
3. Do **not** treat scaffold ✅ as live-validated — each topic’s Validation section is the gate
4. Update screenshots under `assets/images/setup/` only after live proof

---

## 9. Explicitly still out of scope

Carried forward from v1 deferred list (unless a future ADR opens them):

- Multi-region / multi-cluster DR
- Service mesh mTLS
- Azure Policy as a full Kyverno duplicate
- Private AKS / private ACR (may be noted as optional stretch in Phase 21 docs, not required)
- WAF / Front Door / DDoS
- Building Boutique from source / Semgrep on app code (mirror model stays default)
- HSM-backed cosign keys

---

## 10. Progress tracker

| Milestone | Phases | Definition of done (scaffold) | Status |
|-----------|--------|-------------------------------|--------|
| M8a: Plan | 15 | This inventory + ADR-0013 + ROADMAP/plan updated | ✅ |
| M8b: Shift-left CI | 16, 18 | PR pipeline + IaC scan files + Topics 14, 16 | ✅ |
| M8c: Cluster hardening | 17, 21 | NetworkPolicies + PSA/quotas/KV ACL stubs + Topics 15, 19 | ✅ |
| M8d: Supply chain depth | 19 | SBOM/attestation pipeline + policy stubs + Topic 17 | ✅ |
| M8e: Runtime + DAST | 20, 22 | Falco/Defender + optional DAST + Topics 18, 20 | ✅ |

---

## 11. Next action

**Phase 15+ scaffold is complete** (Packages 1–8).

When you rebuild Azure: follow Setup Topics **00–12**, then **14–20** (skip 20 if you do not want DAST). Do not treat scaffold ✅ as live-validated.

Optional follow-ups (not packaged): kubeconform tests, Falcosidekick alerts, Trivy vuln-predicate attestations, tighten Checkov skips after KV Deny.
