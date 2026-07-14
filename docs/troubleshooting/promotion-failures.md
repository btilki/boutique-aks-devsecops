# Promotion failures — troubleshooting

Symptoms and fixes for dev → stage → prod digest promotion ([12-promotion-stage-prod.md](../setup/12-promotion-stage-prod.md)).

---

## Quick diagnostics

| Check | Command |
|-------|---------|
| Argo apps | `kubectl get application -n argocd boutique-dev boutique-stage boutique-prod` |
| Overlay digests | `grep -h digest gitops/apps/boutique/overlays/*/kustomization.yaml` |
| Stage/prod pods | `kubectl get pods -n boutique-stage; kubectl get pods -n boutique-prod` |
| DNS | `dig +short stage-boutique.biroltilki.art boutique.biroltilki.art` |
| Smoke tests | `./tests/integration/promotion-smoke.sh all` |

---

## Git / digest promotion

### Pipeline `promote-digest` fails — overlay path missing

**Cause:** Stage/prod overlays not committed before pipeline run.

**Fix:** Ensure `gitops/apps/boutique/overlays/stage/` and `prod/` exist on `main`.

### `kustomize edit set image` no-op / wrong image

**Cause:** Image name in overlay does not match ACR login server.

**Fix:** Manual edit in overlay `kustomization.yaml`:

```yaml
images:
  - name: <acr>.azurecr.io/frontend
    digest: sha256:<from-digest-manifest>
```

Image name must match post-transform name from `kustomize build`.

### Prod pipeline blocked — waiting for approval

**Expected:** ADO **prod** environment requires manual approval (ADR-0008).

**Fix:** Approve in ADO → Environments → prod → pending deployment. Reject to abort prod Git update.

### Stage and prod digests differ

**Cause:** Promoted different pipeline runs or manual edit error.

**Fix:** Copy exact `images:` block from stage to prod before prod sync. Re-run promotion smoke.

---

## Argo CD

### `boutique-stage` / `boutique-prod` OutOfSync after promotion

**Cause:** Manual sync not triggered; dev auto-sync only.

**Fix:** Argo CD UI → Application → **Sync**. Confirm no `automated` policy on stage/prod apps.

### Sync fails — Kyverno deny

**Cause:** Unsigned digest or non-ACR image in overlay.

**Fix:** Verify digest exists in ACR and cosign signature:

```bash
cosign verify --key /path/to/cosign.pub --tlog-upload=false <image@digest>
```

See [image-signature.md](image-signature.md).

### Prod sync before stage validated

**Process error** — rollback prod overlay to previous commit; sync prod app.

---

## Runtime / ingress

### Stage/prod 502 after sync

**Cause:** Pods not ready; certificate not issued; DNS wrong.

**Fix:**

```bash
kubectl get pods -n boutique-stage
kubectl describe certificate -n boutique-stage boutique-stage-tls
```

Create Azure DNS A records for `stage-boutique` and `boutique` hostnames.

### Prod frontend only one replica unhealthy

**Cause:** Prod overlay sets `replicas: 2` — one node resource pressure.

**Fix:**

```bash
kubectl describe pod -n boutique-prod -l app=frontend
kubectl top nodes
```

Temporarily scale to 1 in `replicas-patch.yaml` for lab if needed.

---

## Smoke test failures

### `promotion-smoke.sh` connection timeout

**Cause:** DNS not propagated or firewall.

**Fix:** Compare `dig` output to ingress LB IP; test with `curl -vk` and Host header.

### Health 200 on dev but not stage with same digest

**Cause:** Namespace-specific ingress or cert issue, not image.

**Fix:** Compare ingress and certificate resources between namespaces.

---

## Rollback issues

### `rollback-smoke.sh` fails after Git revert

**Cause:** Argo not synced after revert; old pods terminating.

**Fix:**

```bash
argocd app sync boutique-<env> --prune
kubectl rollout status deployment/frontend -n boutique-<env>
```

### Rollback to digest no longer in ACR

**Cause:** ACR images deleted (post-teardown partial state).

**Fix:** Re-run mirror pipeline (Topic 09) to repopulate ACR, then re-promote known digest.

---

## Reporting issues

Include: environment (stage/prod), Git commit SHA, Argo sync error, `kubectl get pods -n boutique-<env>`, smoke test output, and whether ADO prod approval was granted.
