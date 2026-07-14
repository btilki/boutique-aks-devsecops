# GitOps bootstrap

Argo CD installation and app-of-apps root applications.

| File | Purpose |
|------|---------|
| `argocd-install/` | Helm chart Argo CD 2.10.7 (chart 6.7.18) |
| `root-app.yaml` | Root app-of-apps |
| `platform-apps.yaml` | platform-root + apps-root child Applications |
| `../projects/` | AppProjects (apply before root) |

**Hostname:** `argocd-boutique.biroltilki.art` (ingress in Topic 06)

## Install (summary)

```bash
kubectl kustomize gitops/bootstrap/argocd-install --enable-helm | kubectl apply -f -
kubectl apply -k gitops/projects/
# configure repo URL, then:
kubectl apply -f gitops/bootstrap/root-app.yaml
```

Full steps: [docs/setup/05-gitops-bootstrap.md](../../docs/setup/05-gitops-bootstrap.md)

**Timing:** SETUP_REQUIRED — Phase 5.
