# Argo CD sync troubleshooting

## Application stuck OutOfSync

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Perpetual OutOfSync on lists | Kubernetes default field ordering | Add ignoreDifferences in Application or use server-side apply |
| Helm values drift | Manual kubectl edit | Enable selfHeal or revert manual change |
| Empty path sync | `gitops/platform` has no resources yet | Expected until Topics 06–11; app shows Synced with 0 resources |

## Repository connection failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `repository not accessible` | Wrong repo URL in Application | Update `<GITHUB_ORG>` / `<REPO_NAME>` in `root-app.yaml`, `platform-apps.yaml`, and platform/app Applications |
| `authentication required` | Private GitHub repo | Add GitHub PAT in Argo CD repo secret (Contents: Read) |
| `revision main must be resolved` | Branch name mismatch | Set `targetRevision` to your default branch |

### GitHub repository URL format

```text
https://github.com/<GITHUB_ORG>/<REPO_NAME>
```

Register in Argo CD:

```bash
argocd repo add "https://github.com/GITHUB_ORG/REPO_NAME" \
  --username <github-user> --password <github-pat>
```

Or configure via UI: **Settings → Repositories**.

## Sync failed — permission denied

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Cannot create cluster-scoped resource | AppProject too restrictive | Check `clusterResourceWhitelist` on project |
| Namespace not allowed | Destination not in project | Add namespace to AppProject `destinations` |

## Bootstrap ordering

1. Install Argo CD (`argocd-install`) **before** Application CRDs
2. Apply **AppProjects** before **root** Application
3. Configure **GitHub repository access** before syncing `root`

## Health check commands

```bash
kubectl get pods -n argocd
kubectl get applications -n argocd
argocd app list
argocd app get root
argocd app sync root --dry-run
```

## Related

- [docs/setup/05-gitops-bootstrap.md](../setup/05-gitops-bootstrap.md)
