# Postmortem checklist

**Audience:** L3 — Operator
**Applies to:** SEV-1 and SEV-2 (lab)
**Prerequisites:** Incident closed or mitigated
**Estimated time:** 30–60 minutes
**Risk level:** Low

## Purpose

Run a **blameless** retrospective so the same failure is cheaper next time.

## When to use / When not to use

**Use** after SEV-1/2 mitigation.
**Do not** use to assign personal blame.

## Prerequisites

- [ ] Timeline notes (alerts, commits, actions)
- [ ] Link to Git commits / pipeline runs

## Procedure

### Step 1: Fill template

```markdown
# Postmortem — YYYY-MM-DD — <short title>

## Summary
What happened in 2–3 sentences.

## Impact
- Environments / hostnames affected
- Duration (detect → mitigate → resolve)
- User-visible effect

## Timeline (UTC)
| Time | Event |
|------|-------|
| | Alert / report |
| | Mitigation steps |
| | Resolved |

## Root cause
What technical condition was necessary for this failure?

## What went well
…

## What went poorly
…

## Action items
| Action | Owner | Due | Linked fix |
|--------|-------|-----|------------|
| | You | | PR / doc / alert |

## SEV / detection gaps
Did we page late? Missing alert? Wrong runbook?
```

**Validation:** At least one preventive action item opened.

**Expected outcome:** Saved under your notes or `docs/` if shareable (no secrets).

**Recovery steps:** N/A.

**Best practices:** Prefer doc/test/alert fixes over “be more careful.”

## End-to-end validation

Action items tracked to completion; update runbooks if steps were wrong.

## Rollback (section-level)

N/A.

## Related alerts and dashboards

Reference alerts that fired in the timeline.

## Security notes

Redact secrets and personal data from published postmortems.

## Automation opportunities

Issue template in GitHub for postmortems.
