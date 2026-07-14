# Argo CD AppProjects

| Project | Scope |
|---------|-------|
| `platform` | ingress-nginx, cert-manager, kyverno, kube-system, argocd |
| `applications` | boutique-dev, boutique-stage, boutique-prod |
| `monitoring` | monitoring namespace |

Apply before root Application:

```bash
kubectl apply -k gitops/projects/
```

See [docs/setup/05-gitops-bootstrap.md](../../docs/setup/05-gitops-bootstrap.md)
