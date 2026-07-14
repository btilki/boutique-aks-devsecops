# CSI secret mount validation example

Isolated test resources live in `gitops/platform/secrets-store-csi/` (namespace `csi-test`).

## Purpose

Verify **Key Vault → Secrets Store CSI → pod volume mount** using the platform UAMI and Workload Identity.

## Prerequisites

- Topic 07 complete
- Key Vault secret `csi-test-secret` created
- Federated credential for `system:serviceaccount:csi-test:csi-test-sa`

## Validate mount

```bash
kubectl get pods -n csi-test
kubectl exec -n csi-test csi-test-pod -- cat /mnt/secrets/csi-test-secret
```

## Cleanup (optional)

```bash
kubectl delete pod csi-test-pod -n csi-test
# Remove test manifests from gitops/platform/kustomization.yaml after validation
```

## Related

- [docs/setup/07-secrets-csi.md](../../docs/setup/07-secrets-csi.md)
