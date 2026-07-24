# Automation opportunities

**Audience:** L3 — Operator / platform
**Applies to:** Toil reduction backlog
**Prerequisites:** Working manual runbooks (this folder)
**Estimated time:** Planning only
**Risk level:** Low

## Purpose

List high-value automations **that do not replace** Setup Guide or these runbooks. Master Prompt: no install-all bypass scripts.

## When to use / When not to use

**Use** when prioritizing hardening (**Phase 15+** / scaffold packages) or after postmortems. Phase 13 was skipped; backlog lives in [phase15-plus.md](../implementation/phase15-plus.md).
**Do not** ship `fix-prod.sh` as the primary ops interface.

## Prerequisites

- [ ] Manual procedure exists and was executed once

## Procedure

### Step 1: Prioritize backlog

| Opportunity | Cuts toil from | Effort | Phase / package | Notes |
|-------------|----------------|--------|-------------|-------|
| ADO **PR** pipeline: pre-commit + `validate.sh` + `kyverno test` | Broken merges | M | Phase 16 / Package 2 | Complements supply-chain on `main` |
| Alert `runbook_url` annotations | SEV triage | S | Ops (anytime) | See [10-alerting.md](10-alerting.md) |
| BoutiqueFrontendDown for stage/prod namespaces | Blind spots | S | Ops (anytime) | Today expr is boutique-dev-centric |
| `ops-status` report script (read-only) | Morning checks | S | Ops (anytime) | Print apps + smoke codes — still document usage here |
| KV network ACL + diagnostics | Security SEC-001 | M | Phase 21 / Package 7 | Manual first when applying |
| NetworkPolicies for boutique-* | East-west | M | Phase 17 / Package 3 | Scaffold then apply |
| IaC scan (Checkov) on PRs | Misconfig merges | M | Phase 18 / Package 4 | See phase15-plus |
| SBOM + cosign attestations | Supply-chain depth | L | Phase 19 / Package 5 | Was deferred in v1 |
| Runtime security (Falco/Defender) | Blind runtime | L | Phase 20 / Package 6 | GitOps/TF stubs |
| Optional DAST (ZAP) | Storefront gaps | M | Phase 22 / Package 8 ✅ | Manual pipeline; advisory by default |
| Grafana synthetic probe CronJob | Gaps between alerts | M | Ops (optional) | Not a Phase 15+ package |
| Quarterly teardown + rebuild drill calendar | DR muscle | S | Ops | Uses Setup + [05](05-disaster-recovery.md) |

**Validation:** Each item still points back to a human-readable runbook.

**Expected outcome:** Ordered Phase **15+** backlog (see [phase15-plus.md](../implementation/phase15-plus.md)).

**Recovery steps:** If automation fails, fall back to this docs tree.

**Best practices:** Automate detection and validation before mutating cluster state.

## End-to-end validation

N/A until an item is implemented — then add its ops notes.

## Rollback (section-level)

Disable failing automation; keep manual path.

## Related alerts and dashboards

N/A.

## Security notes

Automation identities must stay least-privilege (OIDC patterns).

## Automation opportunities

This document *is* the backlog — update when items ship.
