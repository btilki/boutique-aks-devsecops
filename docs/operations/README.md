# Operations — boutique-aks-devsecops

Day-2 runbooks for the **production-pilot** test (single AKS cluster). Bootstrap lives in [`docs/setup/`](../setup/). Deep promotion/teardown procedures live in [`docs/runbooks/`](../runbooks/). Symptom indexes live in [`docs/troubleshooting/`](../troubleshooting/).

**Maturity:** Production pilot · **Owner:** You (solo operator)
**Assumes:** Setup Topics 00–12 completed at least once.

---

## On-call quick links

| Situation | Runbook | First command |
|-----------|---------|---------------|
| Boutique / prod down | [17-common-incidents](17-common-incidents.md) | `kubectl get pods -n boutique-prod` |
| Failed promote / bad digest | [03-rollback](03-rollback.md) | `git log -1 --oneline -- gitops/apps/boutique/overlays/` |
| GitOps stuck / OutOfSync | [17-common-incidents](17-common-incidents.md) | `kubectl get application -n argocd` |
| Cert expiring / TLS error | [14-certificate-rotation](14-certificate-rotation.md) | `kubectl get certificate -A` |
| Node NotReady / capacity | [04-scaling](04-scaling.md) · [17](17-common-incidents.md) | `kubectl get nodes` |
| Full teardown | [teardown runbook](../runbooks/teardown.md) | Read runbook first |

**Smoke suites:** [`tests/README.md`](../../tests/README.md)

---

## Service catalog

| Component | Namespace / resource | Owner | Dashboard | Primary alert |
|-----------|---------------------|-------|-----------|---------------|
| AKS cluster | `aks-boutique-dev-gwc` | You | Cluster Overview (Grafana) | `NodeNotReady` |
| Argo CD | `argocd` | You | Argo UI `argocd-boutique.biroltilki.art` | (manual Synced/Healthy) |
| Boutique storefront | `boutique-{dev,stage,prod}` | You | Boutique Overview | `BoutiqueFrontendDown` |
| Ingress + TLS | `ingress-nginx`, Certificate CRs | You | — | `IngressCertExpiringSoon` |
| Kyverno | `kyverno` + ClusterPolicies | You | — | `KyvernoAdmissionDown` |
| Monitoring stack | `monitoring` | You | Grafana / Alertmanager Overview | (platform rules) |
| ACR + cosign | `acrboutiquedevgwc` · Key Vault | You | ACR portal / pipeline | (pipeline failure) |

**Hostnames:** see [root README](../../README.md).

---

## Escalation (solo test)

| Level | Role | When |
|-------|------|------|
| L1 | You | First response for all SEVs |
| L2 | You (with calm checklist) | > 30 min or promote/ACR/KV risk |
| L3 | Azure subscription / Entra admin (You) | Billing lockout, subscription RBAC, DNS registrar |

Test IR detail: [07-incident-response.md](07-incident-response.md) · [runbooks/incident-response.md](../runbooks/incident-response.md)

---

## Section index

| # | Section | Required |
|---|---------|----------|
| 01 | [Overview](01-overview.md) | Yes |
| 02 | [Deployment](02-deployment.md) | Yes |
| 03 | [Rollback](03-rollback.md) | Yes |
| 04 | [Scaling](04-scaling.md) | Yes |
| 05 | [Disaster recovery](05-disaster-recovery.md) | Thin (rebuild-from-git) |
| 06 | [Backup and restore](06-backup-and-restore.md) | Thin |
| 07 | [Incident response](07-incident-response.md) | Yes |
| 08 | [Health checks](08-health-checks.md) | Yes |
| 09 | [Monitoring](09-monitoring.md) | Yes |
| 10 | [Alerting](10-alerting.md) | Yes |
| 11 | [Logging](11-logging.md) | Yes |
| 12 | [Maintenance](12-maintenance.md) | Yes |
| 13 | [Upgrades](13-upgrades.md) | Yes |
| 14 | [Certificate rotation](14-certificate-rotation.md) | Yes |
| 15 | [Secret rotation](15-secret-rotation.md) | Yes |
| 16 | [Troubleshooting](16-troubleshooting.md) | Yes |
| 17 | [Common incidents](17-common-incidents.md) | Yes |
| 18 | [Recovery procedures](18-recovery-procedures.md) | Yes |
| 19 | [Postmortem checklist](19-postmortem-checklist.md) | Yes |
| 20 | [Automation opportunities](20-automation-opportunities.md) | Yes |

---

## Related documentation

| Doc | Purpose |
|-----|---------|
| [docs/setup/](../setup/) | Bootstrap once |
| [docs/runbooks/](../runbooks/) | Promotion, teardown, IR deep dive |
| [docs/troubleshooting/](../troubleshooting/) | Symptom → fix |
| [docs/security/secrets-management.md](../security/secrets-management.md) | Secrets inventory + rotation |
| [docs/slo/boutique-availability.md](../slo/boutique-availability.md) | Pilot SLO |
| [ARCHITECTURE.md](../../ARCHITECTURE.md) | Component map |

---

## Operations quality checklist

- [x] Sections include Purpose, Commands, Validation, Expected outcome, Recovery, Best practices (template)
- [x] Rollback documented for deployment and upgrades
- [x] GUI steps where CLI is not enough (Argo sync, Grafana)
- [x] Dashboards and alerts named (`Boutique Overview`, alert table in [10](10-alerting.md))
- [x] No secrets in commands — placeholders only
- [x] Commands match repo paths (`tests/integration/`, `gitops/`, `terraform/environments/dev`)
- [x] Common incidents ≥6 playbooks ([17](17-common-incidents.md))
- [x] DR/backup honest for test (rebuild-from-git; no multi-region)
- [x] Postmortem template for SEV-1/2 ([19](19-postmortem-checklist.md))
- [x] Automation section lists opportunities — not setup bypass ([20](20-automation-opportunities.md))

### Alert → runbook annotations

Recommended annotation pattern (apply in PrometheusRule YAML when editing alerts):

```yaml
annotations:
  runbook_url: https://github.com/<GITHUB_ORG>/<REPO_NAME>/blob/main/docs/operations/17-common-incidents.md
  dashboard_url: https://grafana-boutique.biroltilki.art/dashboards
```

See [10-alerting.md](10-alerting.md).

### Next

**Release Prompt** — versioning, release checklist, upgrade guide alignment with [13-upgrades.md](13-upgrades.md).
