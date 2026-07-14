# 05 — GitOps Bootstrap

**Audience:** L2 — Implementer  
**Estimated time:** 90 minutes  
**Prerequisites:** [03-cluster-resources.md](03-cluster-resources.md) ✅ complete (Topic 04 recommended before CI, not blocking GitOps)  
**Creates:** Argo CD v2.10.7, AppProjects, root app-of-apps, platform/apps root Applications  
**Related ADRs:** [0004](../adr/0004-argocd-gitops.md)

---

## Topic goal

When this topic is complete, **Argo CD** runs in the `argocd` namespace, three **AppProjects** (`platform`, `applications`, `monitoring`) exist, and the **root app-of-apps** syncs child Applications for `gitops/platform` and `gitops/apps`. You can reach the Argo CD API/UI via port-forward (HTTPS ingress in Topic 06).

## Why this topic is required

All platform services (ingress, cert-manager, Kyverno, monitoring) and Boutique overlays deploy via GitOps. Argo CD is the reconciliation engine. The app-of-apps pattern keeps bootstrap repeatable: one `root` Application manages `platform-root` and `apps-root` children.

---

## Before you begin

- [ ] `kubectl get nodes` shows Ready nodes (Topic 03)
- [ ] Helm 3.14+ installed (`helm version`)
- [ ] Git repository pushed to **GitHub** (Topic 00 Step 4) — Argo CD pulls from GitHub
- [ ] You know your **GitHub repo URL** (`https://github.com/<GITHUB_ORG>/<REPO_NAME>`) and default branch (`main`)

```bash
kubectl config current-context
helm version
kustomize version   # optional; kubectl kustomize also works
```

---

## Step 5.1: Review GitOps bootstrap layout

### Goal

Understand install order: Argo CD Helm → AppProjects → repository config → root Application.

### Why this step is required

Applying Application CRDs before Argo CD is installed fails. Wrong order wastes debugging time.

### Commands

```bash
cd /path/to/boutique-aks-devsecops
find gitops/bootstrap gitops/projects -type f | sort
head -30 gitops/bootstrap/argocd-install/values.yaml
```

### Expected output

Key files:

| Path | Purpose |
|------|---------|
| `gitops/bootstrap/argocd-install/` | Helm-based Argo CD 2.10.7 |
| `gitops/projects/*.yaml` | AppProjects |
| `gitops/bootstrap/root-app.yaml` | Root app-of-apps |
| `gitops/bootstrap/platform-apps.yaml` | Child Applications |

### Validation

- [ ] Chart version `6.7.18` in `argocd-install/kustomization.yaml`
- [ ] `gitops/platform/kustomization.yaml` exists (empty until Topic 06)

---

## Step 5.2: Install Argo CD

### Goal

Deploy Argo CD into the `argocd` namespace using Kustomize + Helm.

### Why this step is required

Core GitOps controller for all subsequent platform topics.

### Commands

```bash
cd /path/to/boutique-aks-devsecops
kubectl kustomize gitops/bootstrap/argocd-install --enable-helm | kubectl apply -f -
```

Wait for rollouts:

```bash
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s
kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=300s
kubectl rollout status deployment/argocd-application-controller -n argocd --timeout=300s
kubectl get pods -n argocd
```

### Expected output

All pods `Running` / `Completed` (redis, server, repo-server, application-controller).

### Validation

```bash
kubectl get svc -n argocd argocd-server
```

- [ ] `argocd-server` ClusterIP exists
- [ ] No CrashLoopBackOff pods

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `helmCharts` error | Helm not installed | Install Helm 3; use `--enable-helm` |
| OOM on user nodes | Low memory | Check `kubectl top nodes`; reduce resource limits in values.yaml if needed |
| CRD apply timeout | Large chart | Retry apply; wait for API server |

### Recovery

```bash
kubectl kustomize gitops/bootstrap/argocd-install --enable-helm | kubectl delete -f -
# wait; re-apply
```

---

## Step 5.3: Retrieve initial admin password

### Goal

Obtain Argo CD admin credentials for first login.

### Why this step is required

Needed to configure repository access and verify UI.

### Commands

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

### Expected output

Random password string (change after first login in production-like usage).

### Validation

- [ ] Secret exists and decodes to non-empty password

---

## Step 5.4: Port-forward and verify UI

### Goal

Confirm Argo CD API responds locally before ingress (Topic 06).

### Why this step is required

Validates server health independent of DNS/TLS.

### Commands

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Open `http://localhost:8080` — login **admin** / password from Step 5.3.

### Expected output

Argo CD web UI loads; no applications yet (or only defaults).

### Validation

- [ ] UI login succeeds
- [ ] **Settings → Summary** shows version **v2.10.x**

Stop port-forward with Ctrl+C when done.

---

## Step 5.5: Apply AppProjects

### Goal

Create Argo CD projects before Applications reference them.

### Why this step is required

Applications reference `project: platform` — project must exist first.

### Commands

```bash
kubectl apply -k gitops/projects/
kubectl get appprojects -n argocd
```

### Expected output

```text
appproject.argoproj.io/platform created
appproject.argoproj.io/applications created
appproject.argoproj.io/monitoring created
```

### Validation

- [ ] Three AppProjects listed

---

## Step 5.6: Configure GitHub repository URL

### Goal

Replace `<GITHUB_ORG>` and `<REPO_NAME>` placeholders with your GitHub repository in all Argo CD Application manifests.

### Why this step is required

Argo CD cannot sync without a reachable GitHub repository URL. This project uses **GitHub as the sole version control system** — not Azure Repos.

### Commands

Edit these files — use the **same** `repoURL` everywhere:

- `gitops/bootstrap/root-app.yaml`
- `gitops/bootstrap/platform-apps.yaml` (both Applications)
- All `gitops/platform/*/Application.yaml` (and `kyverno/policies-application.yaml`)
- All `gitops/apps/boutique/*-application.yaml` (Topics 10–12)

**GitHub `repoURL` format:**

```text
https://github.com/<GITHUB_ORG>/<REPO_NAME>
```

Example:

```text
https://github.com/biroltilki/boutique-aks-devsecops
```

Verify no placeholders remain:

```bash
grep -r '<GITHUB_ORG>\|<REPO_NAME>' gitops/ || echo "OK: GitHub repoURL patched"
```

Commit and push to `main` on GitHub:

```bash
git add gitops/
git commit -m "chore(gitops): set GitHub repoURL for Argo CD"
git push origin main
```

### Register private GitHub repo credentials (if repo is private)

**Platform:** Argo CD UI or CLI

1. **Settings** → **Repositories** → **Connect repo**
2. Choose **VIA HTTPS**
3. Repository URL: `https://github.com/<GITHUB_ORG>/<REPO_NAME>`
4. Username: your GitHub username; Password: **GitHub PAT** with **Contents: Read** (fine-grained) or classic `repo` scope
5. **Connect**

Or CLI:

```bash
# Install argocd CLI: brew install argocd
argocd login localhost:8080 --username admin --password <PASSWORD> --insecure
argocd repo add "https://github.com/<GITHUB_ORG>/<REPO_NAME>" \
  --username <github-user> --password <GITHUB_PAT>
```

**Public repositories:** Argo CD can sync without credentials if the repo is public.

### Validation

- [ ] `argocd repo list` shows connection **Successful** (private repo) or sync works without auth (public repo)
- [ ] No `<GITHUB_ORG>` or `<REPO_NAME>` literals remain in `gitops/`

---

## Step 5.7: Apply root app-of-apps

### Goal

Register the root Application and child platform/apps roots.

### Why this step is required

Enables Git-driven reconciliation for platform and application paths.

### Commands

```bash
kubectl apply -f gitops/bootstrap/root-app.yaml
```

Sync root (CLI or UI):

```bash
argocd app sync root
argocd app list
```

### Expected output

| Application | Project | Sync Status | Health |
|-------------|---------|-------------|--------|
| root | platform | Synced | Healthy |
| platform-root | platform | Synced | Healthy (0 resources OK) |
| apps-root | applications | Synced | Healthy (0 resources OK) |

Empty `gitops/platform` and `gitops/apps` kustomizations are **expected** until later topics.

### Validation

```bash
kubectl get applications -n argocd
argocd app get platform-root
```

- [ ] `root`, `platform-root`, `apps-root` exist
- [ ] No persistent `Unknown` or `Degraded` health

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `appproject platform not found` | Skipped Step 5.5 | Apply projects |
| Repo sync error | Auth / URL | See [argocd-sync.md](../troubleshooting/argocd-sync.md) |
| `platform-root` OutOfSync empty dir | Normal | Will populate Topic 06+ |

---

## Step 5.8: Validate cluster health

### Goal

Confirm Argo CD control plane is stable for Topic 06 ingress.

### Why this step is required

Baseline before exposing Argo CD via public ingress.

### Commands

```bash
kubectl get pods -n argocd
argocd app list
kubectl auth can-i create applications.argoproj.io -n argocd
```

### Validation

- [ ] All Argo CD pods healthy
- [ ] Three Applications synced
- [ ] You documented Git remote URL and branch for the team

---

## Topic validation (end-to-end)

```bash
kubectl get pods -n argocd
kubectl get appprojects,applications -n argocd
```

**Success criteria:**

- [ ] Argo CD v2.10.x running
- [ ] AppProjects: platform, applications, monitoring
- [ ] Applications: root, platform-root, apps-root synced
- [ ] Repository connection successful
- [ ] Admin UI accessible (port-forward)

Update [Setup Index](README.md) Topic 05 to ✅ when complete.

---

## Topic troubleshooting

See [docs/troubleshooting/argocd-sync.md](../troubleshooting/argocd-sync.md).

---

## Next step

➡️ Continue to **[06-ingress-tls.md](06-ingress-tls.md)** (Topic 06) to expose Argo CD and other services via HTTPS.

Argo CD hostname target: `argocd-boutique.biroltilki.art` ([versions.yaml](../../versions.yaml)).
