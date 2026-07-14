# Image signature verification troubleshooting

## Kyverno verifyImages failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `no matching signatures` | Image not signed | Complete Topic 09 pipeline sign stage |
| `invalid signature` | Wrong public key in policy | Update `02-verify-image-signatures.yaml` with `cosign.pub` PEM |
| Rekor / tlog errors | tlog mismatch | Confirm `rekor.ignoreTlog: true` per ADR-0005 |
| SCT errors | ctlog mismatch | Confirm `ctlog.ignoreSCT: true` |

## cosign CLI verification (ground truth)

```bash
cosign verify \
  --key cosign.pub \
  --insecure-ignore-tlog \
  acrboutiquedevgwc.azurecr.io/frontend@sha256:<digest>
```

Pipeline must sign with:

```bash
cosign sign --key cosign.key --tlog-upload=false <image>
```

## Policy placeholder

Until Topic 09, `02-verify-image-signatures.yaml` contains `<COSIGN_PUBLIC_KEY_PEM>`. Replace with full PEM block:

```text
-----BEGIN PUBLIC KEY-----
...
-----END PUBLIC KEY-----
```

Commit, push, sync `kyverno-policies` Application.

## Unsigned image test

```bash
kubectl apply -f policies/tests/resources/verify-signature-placeholder.yaml --dry-run=server
```

After Topic 09 signing is live, expect **denied** for unsigned digests in `boutique-*` namespaces.

## Related

- [ADR-0005](../adr/0005-cosign-key-based-signing.md)
- [docs/setup/09-ci-pipeline.md](../setup/09-ci-pipeline.md)
