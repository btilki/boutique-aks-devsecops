# Automation opportunities

**Audience:** L3 — Operator / platform
**Applies to:** Toil reduction backlog
**Prerequisites:** Working manual runbooks (this folder)
**Estimated time:** Planning only
**Risk level:** Low

## Purpose

List high-value automations **that do not replace** Setup Guide or these runbooks. Master Prompt: no install-all bypass scripts.

## When to use / When not to use

**Use** when prioritizing hardening (Phase 13) or after postmortems.
**Do not** ship `fix-prod.sh` as the primary ops interface.

## Prerequisites

- [ ] Manual procedure exists and was executed once

## Procedure

### Step 1: Prioritize backlog

| Opportunity | Cuts toil from | Effort | Notes |
|-------------|----------------|--------|-------|
| ADO **PR** pipeline: pre-commit + `validate.sh` + `kyverno test` | Broken merges | M | Complements supply-chain on `main` |
| Alert `runbook_url` annotations | SEV triage | S | See [10-alerting.md](10-alerting.md) |
| BoutiqueFrontendDown for stage/prod namespaces | Blind spots | S | Today expr is boutique-dev-centric |
| `ops-status` report script (read-only) | Morning checks | S | Print apps + smoke codes — still document usage here |
| KV network ACL + diagnostics | Security SEC-001 | M | Manual first |
| NetworkPolicies for boutique-* | East-west | M | Optional Phase 13 |
| Grafana synthetic probe CronJob | Gaps between alerts | M | Optional |
| Quarterly teardown + rebuild drill calendar | DR muscle | S | Uses Setup + [05](05-disaster-recovery.md) |

**Validation:** Each item still points back to a human-readable runbook.

**Expected outcome:** Ordered Phase 13 backlog.

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
