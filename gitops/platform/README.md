# Platform services (GitOps)

Shared cluster services deployed via Argo CD (`platform-root` Application):

| Component | Path | Topic |
|-----------|------|-------|
| NGINX Ingress | `ingress-nginx/` | 06 ✅ files |
| cert-manager | `cert-manager/` | 06 ✅ files |
| Kyverno controller | `kyverno/` | 08 ✅ files |
| Falco (runtime) | `falco/` | 18 ✅ scaffold |
| Secrets Store CSI | `secrets-store-csi/` | 07 ✅ files |
| Monitoring | `monitoring/` | 11 |

See [docs/setup/06-ingress-tls.md](../../docs/setup/06-ingress-tls.md) for ingress + TLS bootstrap.

Admission **policies** live in repo-root `policies/`, not here.
