# cert-manager DNS-01 troubleshooting

## Certificate stuck in `pending` / `Issuing`

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Challenge `pending` | DNS delegation not complete | `dig NS biroltilki.art` — must show Azure NS |
| `azureDNS` authentication error | Workload Identity not configured | Complete federated credential step in Topic 06 |
| Wrong zone | `hostedZoneName` mismatch | Must be `biroltilki.art` and RG `rg-boutique-dev-gwc` |
| Wrong subscription ID | Placeholder not replaced | Patch `cluster-issuer-letsencrypt.yaml` |

## Workload Identity for cert-manager

cert-manager must use the **platform UAMI** (`uami-boutique-platform`) with:

- **Azure RBAC:** DNS Zone Contributor on DNS zone (Topic 03 identities module)
- **Federated credential** subject: `system:serviceaccount:cert-manager:cert-manager`

Verify:

```bash
az identity federated-credential list \
  --identity-name uami-boutique-platform \
  --resource-group rg-boutique-dev-gwc -o table
```

## Inspect challenges

```bash
kubectl get clusterissuer letsencrypt-prod
kubectl get certificate -A
kubectl describe certificate argocd-server-tls -n argocd
kubectl describe challenge -A
kubectl logs -n cert-manager deploy/cert-manager --tail=50
```

## Rate limits (Let's Encrypt)

| Symptom | Fix |
|---------|-----|
| `429 too many certificates` | Wait 7 days or use staging issuer for tests |
| Repeated failed orders | Fix DNS-01 before retrying; check challenge TXT records in Azure DNS |

### Staging issuer (optional test)

Duplicate ClusterIssuer with `server: https://acme-staging-v02.api.letsencrypt.org/directory` and name `letsencrypt-staging`.

## Ingress TLS mismatch

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| HTTPS works but cert wrong | Old secret | Delete `argocd-server-tls` secret; re-sync |
| 502 from ingress | `backend-protocol` wrong | Argo CD uses HTTP backend — annotation `nginx.ingress.kubernetes.io/backend-protocol: HTTP` |

## Related

- [docs/setup/06-ingress-tls.md](../setup/06-ingress-tls.md)
