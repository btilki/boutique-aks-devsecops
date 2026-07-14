# Resilience and disaster recovery

## Maturity

Production **pilot**: rebuild-from-Git is the primary DR strategy. No multi-region failover.

## Failure scenarios

| Scenario | Impact | Detection | Mitigation | Recovery |
|----------|--------|-----------|------------|----------|
| Single node loss | Pod reschedule | Node NotReady alert | ReplicaSets, autoscaler | Automatic |
| AZ outage | Partial/full unavailability | Azure status, alerts | Multi-AZ pool optional | Manual rebuild |
| NGINX / LB failure | All ingress down | Blackbox probe, Argo | Redeploy ingress app | Argo sync |
| GitOps desync | Wrong/stale workloads | Argo OutOfSync | Manual sync / rollback | Argo history |
| TF state lock | Blocked applies | terraform error | Break lease / versioning | Restore state blob |
| cert-manager expiry | TLS warnings | cert-manager alert | Fix DNS-01 creds | Certificate renew |
| Kyverno deny loop | Deployments blocked | Policy reports, events | Audit mode temporarily | Fix images/signatures |
| ACR unavailable | ImagePullBackOff | Pod events | Restore ACR | Re-mirror pipeline |
| Observability down | Reduced visibility | Prometheus self-monitoring | Helm rollback | Argo sync |
| ADO OIDC failure | CI blocked | Pipeline auth errors | Fix federated creds | Re-run verify script |

## DR targets (pilot)

| Metric | Target |
|--------|--------|
| RTO (full platform) | 4–8 hours |
| RPO (Terraform state) | 0 with blob versioning |
| RPO (application cart data) | Ephemeral (redis emptyDir) |

## Stateful vs stateless

| Stateful | Stateless |
|----------|-----------|
| Terraform remote state | Boutique microservices (config in Git) |
| ACR images (until teardown) | Ingress controllers |
| Key Vault secrets | Redis cart data (demo) |
| Prometheus TSDB (if PVC) | Frontend sessions |

## Backup targets

| Asset | Method |
|-------|--------|
| Terraform state | Azure Storage versioning |
| Git manifests | Git remote |
| Key Vault | Soft delete + purge protection (TF module) |
| Grafana dashboards | Git (`gitops/platform/monitoring/`) |

## Rebuild order

1. Terraform bootstrap (if state storage retained)
2. Terraform env (network → AKS → ACR → KV)
3. Argo CD bootstrap → platform services
4. Kyverno policies
5. CI mirror/sign (Phase 9) — required after ACR destroy
6. Boutique overlays
7. Observability

Reverse order documented in `docs/setup/13-teardown.md`.

## Teardown (Phase 14)

Destroys **AKS, ACR**, load balancers, and other billable resources. Terraform bootstrap state may be retained by explicit choice.
