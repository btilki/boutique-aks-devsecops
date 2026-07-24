# Microsoft Defender for Containers — opt-in only (ADR-0015)

**Do not enable by default** on the production-pilot rebuild. Falco is the in-cluster runtime SSOT for this repo.

## Why opt-in

- Usually pairs with **Log Analytics** / Defender plans (cost) — conflicts with [ADR-0012](../../../docs/adr/0012-loki-in-cluster-logging.md) default path.
- This module already **`ignore_changes`** on `microsoft_defender` so subscription-level enablement does not fight Terraform.

## Apply later (manual)

1. Azure Portal → **Microsoft Defender for Cloud** → Environment settings → subscription → enable **Containers** (and related plans as needed).
2. Or use Azure CLI / Policy at subscription scope (outside this module).
3. Confirm AKS shows Defender profile without a Terraform plan trying to remove it (ignore_changes covers drift).

## Future TF (not wired)

If you later manage Defender in-module, add an explicit `microsoft_defender { log_analytics_workspace_id = ... }` block, **remove** it from `lifecycle.ignore_changes`, and accept Log Analytics cost. Prefer a dedicated ADR before doing so.

## Related

[docs/setup/18-runtime-security.md](../../../docs/setup/18-runtime-security.md)
