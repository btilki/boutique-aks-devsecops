# Incident response (solo lab)

Lightweight incident handling for a **single-operator** Azure DevSecOps lab. Not a full enterprise IR program.

**Related:** [promotion-rollback.md](promotion-rollback.md), [monitoring-alerting.md](../troubleshooting/monitoring-alerting.md)

---

## Severity levels

| Level | Example | Response time (lab) |
|-------|---------|---------------------|
| **S1** | Prod/stage storefront down | Immediate |
| **S2** | Kyverno/Argo CD broken; no deploys | Same day |
| **S3** | Single non-critical pod crash loop | Next maintenance window |
| **S4** | Informational alert / cert expiry warning | Planned fix |

---

## First response checklist

1. **Acknowledge** — Note time, environment (dev/stage/prod), alert name
2. **Triage** — Is user-facing Boutique down?
   ```bash
   ./tests/integration/dev-smoke.sh
   ./tests/integration/promotion-smoke.sh stage   # if stage affected
   ```
3. **Dashboards** — Grafana Boutique Overview + Prometheus alerts
4. **Recent changes** — Last Git commit, Argo sync, pipeline run, Terraform apply
5. **Contain** — Stop promotion; do not sync prod if stage/dev unhealthy

---

## Common scenarios

### Boutique frontend down

```bash
kubectl get pods -n boutique-<env>
kubectl logs -n boutique-<env> deploy/frontend --tail=50
kubectl describe ingress -n boutique-<env> boutique-frontend
```

Rollback: [promotion-rollback.md](promotion-rollback.md)

### Kyverno blocking deploys

```bash
kubectl get policyreport -A
kubectl describe clusterpolicy
```

See [kyverno-admission.md](../troubleshooting/kyverno-admission.md)

### Certificate / TLS failure

```bash
kubectl get certificate -A
kubectl describe clusterissuer letsencrypt-prod
```

See [cert-manager-dns01.md](../troubleshooting/cert-manager-dns01.md)

### Pipeline / supply chain failure

See [pipeline-failures.md](../troubleshooting/pipeline-failures.md) and [image-signature.md](../troubleshooting/image-signature.md)

### Suspected compromise

1. Revoke ADO pipeline access; disable service connection
2. Rotate cosign key pair in Key Vault; update Kyverno policy
3. Do **not** sync prod; scale affected deployments to 0
4. Preserve logs: Loki/Grafana Explore, `kubectl logs`, Argo CD audit
5. Rebuild from signed known-good digests after root cause

---

## Communication (solo lab)

| Audience | Channel |
|----------|---------|
| Yourself | Incident notes in repo or personal log |
| Stakeholders | Email/status doc if demo deadline |

No on-call rotation in v1.

---

## Post-incident

- [ ] Root cause documented (1 paragraph minimum)
- [ ] Smoke tests green
- [ ] Update runbook or troubleshooting doc if new pattern
- [ ] SLO error budget noted ([boutique-availability.md](../slo/boutique-availability.md))

---

## When to teardown instead of fix

- Unbounded Azure cost with no time to debug
- Corrupted cluster state / etcd issues on lab cluster
- End of project milestone

See [teardown.md](teardown.md)
