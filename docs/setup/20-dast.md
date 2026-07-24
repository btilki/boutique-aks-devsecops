# 20 — DAST (OWASP ZAP baseline, optional)

**Audience:** L2 — Implementer
**Estimated time:** 30–45 minutes when Boutique HTTPS is live
**Prerequisites:** [10-boutique-dev.md](10-boutique-dev.md) ✅ (dev storefront reachable) · ADO project (Topic 09/14 pattern)
**Creates:** Manual ADO DAST pipeline; ZAP HTML/JSON artifacts
**Related ADRs:** [0017](../adr/0017-optional-zap-dast.md)
**Mode:** Pipeline scaffolded. Running the scan needs a **live** target (**Apply later**). This topic is **optional** — Phase 15+ is complete without enforcing DAST.

---

## Topic goal

When this topic is complete, you can manually run **OWASP ZAP baseline** against `https://dev-boutique.<DNS_ZONE>` (or another hostname **you operate**), download reports, and optionally fail the job on WARN/FAIL.

## Why this topic is required

Container/IaC/admission gates do not exercise the HTTP UI. Baseline DAST closes that portfolio gap without blocking every merge (ADR-0017: advisory by default).

---

## Before you begin

```bash
cd /path/to/boutique-aks-devsecops
ls pipelines/azure-pipelines-dast.yml \
  pipelines/templates/dast-zap.yml \
  pipelines/templates/dast-variables.yml \
  tests/ci/dast-zap.sh
```

**Rules of engagement**

- Scan **only** Boutique (or other) hosts in **your** subscription/DNS
- Prefer **dev**; avoid hammering prod
- Do not point ZAP at third-party sites

---

## Step 20.1: Review pipeline design

### Goal

Understand manual trigger, parameters, and advisory mode.

| Item | Value |
|------|--------|
| Trigger | `none` (manual) |
| Tool | `zap-baseline.py` in `ghcr.io/zaproxy/zaproxy:2.15.0` |
| Default target | `https://dev-boutique.biroltilki.art` |
| Default gate | `failOnWarn=false` (artifact only) |
| Artifact | `zap-baseline` (`zap-report.html`, `zap-report.json`) |

### Validation

- [ ] Not referenced from PR or supply-chain pipelines

---

## Step 20.2: Local dry-run (optional, needs live URL + Docker)

```bash
chmod +x tests/ci/dast-zap.sh
./tests/ci/dast-zap.sh "https://dev-boutique.<DNS_ZONE>"
# Reports → .zap-out/ (gitignored if you add it; default path is local only)
```

Skip this step when Azure is torn down.

---

## Step 20.3: Register ADO pipeline — **Apply later**

1. ADO → **Pipelines** → **New pipeline** → GitHub → this repo
2. Existing YAML → `pipelines/azure-pipelines-dast.yml`
3. Name e.g. `boutique-dast-zap`
4. Run → set parameters:
   - `targetUrl`: your live dev HTTPS URL
   - `failOnWarn`: false (first runs)

### Validation

- [ ] Job reaches ZAP container; preflight `curl` succeeds
- [ ] Artifact `zap-baseline` downloadable
- [ ] HTML report opens in a browser

---

## Step 20.4: Triage findings

1. Open `zap-report.html`
2. Classify false positives (CSP headers, cookie flags on demo app, etc.)
3. File follow-ups only for issues you will fix in **platform** config (ingress headers, TLS) — Boutique app code is upstream-mirrored (ADR-0009)

Optional gate: re-run with `failOnWarn=true` once noise is understood.

---

## Rollback

- Disable or delete the ADO DAST pipeline registration
- Leave YAML in Git (optional portfolio evidence)

---

## End-to-end validation checklist

### Scaffold

- [x] `azure-pipelines-dast.yml` + templates + ADR-0017 + this topic
- [x] Local helper `tests/ci/dast-zap.sh`

### Apply later

- [ ] Manual pipeline green (or advisory with reports) against live dev
- [ ] Report archived / triaged

---

## Related docs

| Doc | Role |
|-----|------|
| [10-boutique-dev.md](10-boutique-dev.md) | Storefront live |
| [14-pr-ci.md](14-pr-ci.md) | Shift-left (not DAST) |
| [pipelines/README.md](../../pipelines/README.md) | Pipeline index |
| [phase15-plus.md](../implementation/phase15-plus.md) | Phase 15+ complete after this package |
