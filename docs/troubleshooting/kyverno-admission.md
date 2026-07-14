# Kyverno admission troubleshooting

## Policy blocks expected platform pods

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Argo CD sync fails on platform images | Registry allowlist too strict | Confirm excludes for `argocd`, `ingress-nginx`, `cert-manager`, `kyverno`, `kube-system` |
| CSI test pod blocked | `csi-test` not excluded | Remove test pod (Topic 07) or add namespace exclude |

## Policy not enforcing

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Violations allowed | `validationFailureAction: Audit` | Policies use `Enforce` — check live ClusterPolicy |
| Wrong policy version | Old CRD | `kubectl get clusterpolicy` — re-sync `kyverno-policies` |
| Webhook timeout | Kyverno not ready | `kubectl get pods -n kyverno` |

## Debugging commands

```bash
kubectl get clusterpolicy
kubectl describe clusterpolicy registry-allowlist
kubectl get policyreport -A
kubectl logs -n kyverno -l app.kubernetes.io/component=admission-controller --tail=50
```

## Test admission manually

```bash
kubectl apply -f policies/tests/resources/deny-non-acr-image.yaml --dry-run=server
```

Expect: denied by `registry-allowlist`.

## Related

- [docs/setup/08-admission-policies.md](../setup/08-admission-policies.md)
- [image-signature.md](image-signature.md)
