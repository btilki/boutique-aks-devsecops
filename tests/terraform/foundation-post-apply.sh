#!/usr/bin/env bash
# Post-apply smoke checks after Topic 03 (AKS, ACR, Key Vault).
# Usage: from repo root after terraform apply in environments/dev:
#   ./tests/terraform/foundation-post-apply.sh
# Requires: az CLI logged in, kubectl, terraform outputs.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEV_DIR="${REPO_ROOT}/terraform/environments/dev"

cd "${DEV_DIR}"

RG="$(terraform output -raw resource_group_name)"
CLUSTER="$(terraform output -raw aks_cluster_name)"
ACR_NAME="$(terraform output -raw acr_name)"
KV_NAME="$(terraform output -raw key_vault_name)"

echo "[post-apply] Resource group: ${RG}"
echo "[post-apply] AKS cluster: ${CLUSTER}"
echo "[post-apply] ACR: ${ACR_NAME}"
echo "[post-apply] Key Vault: ${KV_NAME}"

echo "[post-apply] Fetching AKS credentials..."
az aks get-credentials --resource-group "${RG}" --name "${CLUSTER}" --overwrite-existing

echo "[post-apply] kubectl get nodes"
kubectl get nodes -o wide

echo "[post-apply] ACR login and list repositories"
az acr login --name "${ACR_NAME}"
az acr repository list --name "${ACR_NAME}" -o table || true

echo "[post-apply] Key Vault show"
az keyvault show --name "${KV_NAME}" --resource-group "${RG}" --query "{name:name, uri:properties.vaultUri}" -o json

echo "[post-apply] OIDC issuer URL"
terraform output -raw aks_oidc_issuer_url

echo "[post-apply] OK"
