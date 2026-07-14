#!/usr/bin/env bash
# Print Azure DevOps ARM service connection values from Terraform outputs.
# Authority: docs/setup/04-ado-oidc.md — use these exact values in ADO GUI.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV_DIR="${REPO_ROOT}/terraform/environments/dev"

cd "${DEV_DIR}"

echo "=== ADO ARM Service Connection (Workload identity federation) ==="
echo
echo "Create in Azure DevOps:"
echo "  Project settings → Service connections → New → Azure Resource Manager"
echo "  Authentication: Workload Identity federation (manual)"
echo
echo "| Field | Value |"
echo "|-------|-------|"
echo "| Service connection name | $(terraform output -raw ado_service_connection_name) |"
echo "| Subscription ID | $(terraform output -raw azure_subscription_id) |"
echo "| Subscription name | (select in portal) |"
echo "| Resource group | $(terraform output -raw resource_group_name) |"
echo "| Service principal / client ID | $(terraform output -raw ado_pipeline_identity_client_id) |"
echo "| Tenant ID | $(terraform output -raw azure_tenant_id) |"
echo
echo "Federated credential (already created by Terraform):"
echo "  Issuer:   $(terraform output -raw ado_oidc_issuer)"
echo "  Subject:  $(terraform output -raw ado_oidc_subject)"
echo
echo "Grant pipeline access: check 'Grant access permission to all pipelines' or authorize per pipeline."
echo
echo "After creating the service connection, run: scripts/verify-oidc-trust.sh"
