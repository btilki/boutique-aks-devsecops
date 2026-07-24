# Boutique NetworkPolicies (Package 3 / Topic 15)

## Intent

**Ingress default-deny** in each `boutique-*` namespace, plus allow rules for the Online Boutique v0.10.5 service graph and north-south traffic from `ingress-nginx` (and scrape from `monitoring`).

Egress is **not** default-denied in this package (DNS and ClusterIP calls keep working without extra egress rules).

## Service graph (who may call whom)

```text
internet → ingress-nginx → frontend:8080
loadgenerator → frontend:8080
monitoring → frontend:8080   (ServiceMonitor; optional)

frontend → productcatalog:3550, currency:7000, cart:7070,
           recommendation:8080, shipping:50051, checkout:5050, ad:9555

checkout → productcatalog, shipping, payment:50051, email:8080,
           currency, cart

recommendation → productcatalog:3550
cart → redis-cart:6379
```

## Enforcement prerequisite

These objects are inert unless the cluster has a NetworkPolicy plugin:

| Setting | Where |
|---------|--------|
| `network_policy = "azure"` | `terraform/modules/aks` via `var.network_policy` / env tfvars (Topic 15) |

Azure CNI **without** `network_policy` stores policies but does not enforce them.

## Apply

Included from [../kustomization.yaml](../kustomization.yaml). Overlays inherit automatically after Argo sync.

## Related

[docs/setup/15-network-policies.md](../../../../../docs/setup/15-network-policies.md)
