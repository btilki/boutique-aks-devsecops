# What this reference claims

Closed reference: Azure was torn down after Setup Topics **00–13**. Nothing here requires a live cluster to read. Screenshots: [`assets/images/`](../assets/images/README.md).

ADO mirrors and signs images, Git stores digest pins, and Argo CD reconciles. The reference proved that path once, then the cloud resources were removed.

## Operated, then torn down (Topics 00–13)

- Terraform foundation, ADO OIDC, Argo CD, NGINX and cert-manager, Key Vault CSI
- Kyverno Enforce: ACR allowlist, deny `:latest`, cosign verify, Pod Security baseline (Boutique workloads)
- Mirror → Trivy → cosign → digest promotion; Boutique on `boutique-dev` / `boutique-stage` / `boutique-prod`
- Grafana; in-cluster Loki; ADO environment approval before prod
- Teardown validated ([setup/13-teardown](setup/13-teardown.md))

SBOM generation, cosign attestations, PR CI, NetworkPolicies, Falco, namespace/KV hardening, and optional DAST exist in Git as later guides. They were **not** required for the closed Topics 00–13 path. See [setup README — optional after rebuild](setup/README.md#optional-after-rebuild--not-part-of-the-closed-reference).

**Present in Git ≠ lived proof.** After the closed run, some Topic 14–20 files sit on default trees (Boutique base `networkpolicies` / `hardening`, Kyverno `05-verify-sbom-attestation` in Audit). Pipeline SBOM/attest stays **off** by default (`enableSbomAttest: "false"`). NetworkPolicy **enforcement** still needs `aks_network_policy` set. Falco Application and `runtime-security` alert stay off default sync until Topic 18.

## Limits inside the operated path

These are deliberate reference choices. Each limit maps to a file you can open.

| Limit | Where to point |
|-------|----------------|
| Public API server, system pool size 1, no availability zones | `terraform/modules/aks` |
| Trivy fails only on CRITICAL; `--ignore-status fixed` skips CVEs that already have an upstream fix; images are mirrored, not rebuilt | `pipelines/templates/build-scan-sign.yml` |
| Cosign key passphrase is empty; Key Vault RBAC is the control | same pipeline, `COSIGN_PASSWORD` |
| Signature verification skips platform namespaces (`kube-system`, `kyverno`, `argocd`, `ingress-nginx`, `cert-manager`, `monitoring`) | `policies/kyverno/cluster/02-verify-image-signatures.yaml` |
| Transparency log is off (`--tlog-upload=false`) | [ADR-0005](adr/0005-cosign-key-based-signing.md) |
| SBOM / cosign attest may exist in pipeline YAML; default toggle is off | Optional after rebuild ([ADR-0014](adr/0014-sbom-cosign-attestations.md)); enable via Topic 17 (`enableSbomAttest`); not part of the closed 00–13 claim set |

## Claims to avoid

- “This is production-ready.” It is a **production reference** on one cluster. State that boundary first.
- “`prod` is a separate production estate.” It is a namespace next to `dev` and `stage`.
- “Falco / NetworkPolicy / DAST blocked deploys in the lived run.” They did not. Falco is off the default sync path; NetworkPolicy does not enforce while `aks_network_policy` is `null`.
- “We rebuild Boutique from source.” The default path mirrors Google’s published images ([ADR-0009](adr/0009-mirror-upstream-images.md)).
- “SBOM attestations were proven in the closed run.” Attest paths are in Git for apply after rebuild; do not claim them as lived Topics 00–13 proof.

## Related

- Architecture summary: [`../ARCHITECTURE.md`](../ARCHITECTURE.md)
- CI / promotion / rollback contracts: [`ci.md`](ci.md) · [`promotion.md`](promotion.md) · [`rollback.md`](rollback.md)
- Threat model: [`security/threat-model.md`](security/threat-model.md)
- Setup index: [`setup/README.md`](setup/README.md)
