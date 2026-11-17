# Examples

## Purpose

Runnable demos isolated from production GitOps paths.

## Contents

| Path | When |
|------|------|
| [`csi-secret-test/`](csi-secret-test/README.md) | After Topic 07 — confirm Key Vault → CSI mount |

## Quick run (CSI test)

From repo root, after Topic 07 and the `csi-test` pod is scheduled:

```bash
kubectl get pods -n csi-test
kubectl exec -n csi-test csi-test-pod -- cat /mnt/secrets/csi-test-secret
```

Full prerequisites and cleanup: [csi-secret-test/README.md](csi-secret-test/README.md) · [docs/setup/07-secrets-csi.md](../docs/setup/07-secrets-csi.md)

## Numbering

Roadmap **Phase** numbers differ from Setup **Topic** numbers. See [ROADMAP.md](../ROADMAP.md) and [docs/setup/README.md](../docs/setup/README.md).
