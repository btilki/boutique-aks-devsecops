# Certificate rotation

**Audience:** L3 — Operator
**Applies to:** cert-manager Certificates / ClusterIssuer
**Prerequisites:** Azure DNS-01; platform UAMI DNS Zone Contributor
**Estimated time:** 15–45 minutes
**Risk level:** Medium

## Purpose

Keep Let’s Encrypt certificates valid for Boutique, Grafana, and Argo CD hostnames.

## When to use / When not to use

**Use** on `IngressCertExpiringSoon`, browser TLS errors, or DNS zone changes.
**Do not** manually delete Secrets before a replacement Certificate is Ready (causes outage).

## Prerequisites

- [ ] `kubectl get clusterissuer`
- [ ] DNS zone still delegated to Azure DNS

## Procedure

### Step 1: Inspect certificates

**Commands:**

```bash
kubectl get certificate -A
kubectl describe certificate -n boutique-prod boutique-frontend   # name may vary — list first
kubectl get certificaterequest,order,challenge -A | head -40
```

**Validation:** `READY=True`; not within expiry warning window without renew.

**Expected outcome:** Identify failing Challenge / DNS reason.

**Recovery steps:** [cert-manager-dns01.md](../troubleshooting/cert-manager-dns01.md)

**Best practices:** Fix DNS-01 before force-renew thrash.

### Step 2: Trigger renew (if stuck)

**Commands:**

```bash
# Annotate to force renew (cert-manager supported approach — prefer describe root cause first)
cmctl renew -n boutique-prod <certificate-name>   # if cmctl installed
# Or delete CertificateRequest after fixing DNS (controller recreates)
```

**Validation:** New Secret tls.crt NotAfter updated; HTTPS curl works.

**Expected outcome:** Browse `https://boutique.biroltilki.art` without warning.

### Step 3: Platform UAMI / DNS

Confirm platform identity still has DNS Zone Contributor if Challenges stuck on TXT.

## End-to-end validation

```bash
echo | openssl s_client -servername boutique.biroltilki.art -connect boutique.biroltilki.art:443 2>/dev/null | openssl x509 -noout -dates
```

## Rollback (section-level)

Restore previous TLS Secret only as emergency (will mismatch renew) — better fix issuer.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| `IngressCertExpiringSoon` | — | `{namespace="cert-manager"}` |

## Security notes

Let’s Encrypt rate limits — avoid delete/recreate loops.

## Automation opportunities

Alert already defined — ensure notification channel in lab.
