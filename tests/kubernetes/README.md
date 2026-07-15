# Kubernetes manifest tests

**Status:** Placeholder — no kubeconform suite yet (TEST-GAP-K8S-001).

When implemented, run something like:

```bash
# Example only — script not committed until tool + versions pinned
find gitops -name '*.yaml' \
  ! -path '*/charts/*' \
  -print0 | xargs -0 kubeconform -kubernetes-version 1.34 -summary
```

Pin `kubeconform` in [versions.yaml](../../versions.yaml) before adding a shell wrapper here.
