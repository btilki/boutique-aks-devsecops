# Argo CD AppProjects

Three projects isolate destination namespaces. Apply before the root Application.

| Project | Destination namespaces | Typical Applications |
|---------|------------------------|----------------------|
| `platform` | `argocd`, `ingress-nginx`, `cert-manager`, `kyverno`, `kube-system`, `csi-test`, `falco` | `root`, `platform-root`, `apps-root`; ingress-nginx, cert-manager, Kyverno, CSI, Falco |
| `applications` | `boutique-dev`, `boutique-stage`, `boutique-prod` | `boutique-dev`, `boutique-stage`, `boutique-prod` |
| `monitoring` | `monitoring`, `kube-system`, `default` | kube-prometheus-stack, Loki, Promtail, OpenTelemetry, monitoring-extras |

`apps-root` uses **`platform`** because it only creates Application CRs in `argocd`. Boutique workloads use **`applications`**. Monitoring Helm releases use **`monitoring`** only.

```bash
kubectl apply -k gitops/projects/
```

See [docs/setup/05-gitops-bootstrap.md](../../docs/setup/05-gitops-bootstrap.md)
