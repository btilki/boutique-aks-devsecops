#!/usr/bin/env bash
# Verify ADO OIDC federation Terraform outputs and Azure federated credential existence.
# Usage: scripts/verify-oidc-trust.sh
# See docs/setup/04-ado-oidc.md and docs/troubleshooting/ado-oidc.md
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV_DIR="${REPO_ROOT}/terraform/environments/dev"

cd "${DEV_DIR}"

RG="$(terraform output -raw resource_group_name)"
CLIENT_ID="$(terraform output -raw ado_pipeline_identity_client_id)"
ISSUER="$(terraform output -raw ado_oidc_issuer)"
SUBJECT="$(terraform output -raw ado_oidc_subject)"
SC_NAME="$(terraform output -raw ado_service_connection_name)"

echo "[verify-oidc] Resource group: ${RG}"
echo "[verify-oidc] Pipeline identity client ID: ${CLIENT_ID}"
echo "[verify-oidc] Expected issuer: ${ISSUER}"
echo "[verify-oidc] Expected subject: ${SUBJECT}"
echo "[verify-oidc] Service connection name: ${SC_NAME}"

echo "[verify-oidc] Checking user-assigned identity..."
az identity list --resource-group "${RG}" --query "[?clientId=='${CLIENT_ID}'].{name:name, clientId:clientId}" -o table

IDENTITY_NAME="$(az identity list --resource-group "${RG}" --query "[?clientId=='${CLIENT_ID}'].name" -o tsv)"
if [[ -z "${IDENTITY_NAME}" ]]; then
  echo "ERROR: Pipeline identity not found in resource group ${RG}" >&2
  exit 1
fi

az identity federated-credential list --identity-name "${IDENTITY_NAME}" --resource-group "${RG}" \
  --query "[].{name:name, issuer:issuer, subject:subject}" -o table

echo "[verify-oidc] Checking role assignments on ACR and Key Vault..."
ACR_ID="$(az acr show -n "$(terraform output -raw acr_name)" --query id -o tsv)"
KV_ID="$(az keyvault show -n "$(terraform output -raw key_vault_name)" --query id -o tsv)"

az role assignment list --assignee "${CLIENT_ID}" --scope "${ACR_ID}" --query "[].roleDefinitionName" -o tsv | grep -q AcrPush \
  && echo "[verify-oidc] AcrPush on ACR: OK" \
  || echo "[verify-oidc] WARN: AcrPush not found on ACR (may still be propagating)"

az role assignment list --assignee "${CLIENT_ID}" --scope "${KV_ID}" --query "[].roleDefinitionName" -o tsv | grep -q "Key Vault Secrets User" \
  && echo "[verify-oidc] Key Vault Secrets User: OK" \
  || echo "[verify-oidc] WARN: Key Vault Secrets User not found (may still be propagating)"

echo
echo "[verify-oidc] Manual check: run a test ADO pipeline job using service connection '${SC_NAME}' with:"
echo "  az account show"
echo
echo "[verify-oidc] Done — review WARN lines; RBAC can take 1–5 minutes to propagate."
