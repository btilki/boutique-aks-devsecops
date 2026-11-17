# Automation opportunities

Audience: Operator / platform
Use when prioritizing toil reduction after rebuilds or postmortems. Backlog lives here — update rows when something ships.

Related: [phase15-plus.md](../implementation/phase15-plus.md) · [reference-claims.md](../reference-claims.md)

## Purpose

Separate **already scaffolded** Phase 15+ work (apply after rebuild) from **true backlog** items that still need design or implementation.

## Scaffolded in Git (apply later — not closed-run proof)

These have setup topics, pipelines, or GitOps stubs. Local validation works today; live Azure/ADO proof waits for rebuild.

| Item | Setup / entry | Notes |
|------|----------------|-------|
| ADO PR pipeline: pre-commit + `validate.sh` + Checkov + `kyverno test` | Topics [14](../setup/14-pr-ci.md), [16](../setup/16-iac-scanning.md) | `pipelines/azure-pipelines-pr.yml`, `make pr-validate` |
| IaC scan (Checkov) on PRs | Topic 16 | Same four-job PR pipeline as above |
| NetworkPolicies for Boutique | Topic [15](../setup/15-network-policies.md) | Manifests in Git; enforcement needs `aks_network_policy=azure` |
| SBOM + cosign attestations | Topic [17](../setup/17-sbom-attestations.md) | Default off (`enableSbomAttest`); YAML + Kyverno Audit policy in repo |
| Runtime security (Falco) + Defender opt-in doc | Topic [18](../setup/18-runtime-security.md) | Falco not on default `platform-root` sync until you enable it |
| KV ACL + PSA/quotas | Topic [19](../setup/19-namespace-hardening.md) | Terraform/GitOps stubs; Checkov skips document reference tradeoffs |
| Optional DAST (ZAP) | Topic [20](../setup/20-dast.md) | Manual `azure-pipelines-dast.yml`; advisory by default |

## Backlog (not yet a full operator shortcut)

| Opportunity | Cuts toil from | Effort | Notes |
|-------------|----------------|--------|-------|
| Alert `runbook_url` annotations | SEV triage | S | See [10-alerting.md](10-alerting.md) |
| BoutiqueFrontendDown for stage/prod namespaces | Blind spots | S | Today expr is boutique-dev-centric |
| `ops-status` report script (read-only) | Morning checks | S | Print apps + smoke codes; document in this repo when added |
| KV network ACL + diagnostics (live apply) | Security SEC-001 | M | Scaffold in Topic 19; operators still run manual path first |
| Grafana synthetic probe CronJob | Gaps between alerts | M | Not a Phase 15+ package |
| Quarterly teardown + rebuild drill calendar | DR muscle | S | Uses Setup + [05-disaster-recovery.md](05-disaster-recovery.md) |

**Best practices:** Automate detection and validation before mutating cluster state. If automation fails, fall back to setup and runbooks — do not replace documented procedures with a single `fix-prod.sh`.

## Security notes

Automation identities must stay least-privilege (OIDC patterns).

## Maintenance

When a backlog item ships, move it to the scaffolded table (or link the new runbook) and trim duplicate mentions elsewhere.
