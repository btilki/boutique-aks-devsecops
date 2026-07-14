#!/usr/bin/env bash
# Guarded platform teardown — destroys Terraform-managed Azure resources (Topics 02–04).
# ACR is destroyed per ADR-0010. Bootstrap state storage is retained unless --destroy-bootstrap.
#
# Usage:
#   ./scripts/operations/teardown.sh --confirm destroy-boutique-platform
#   ./scripts/operations/teardown.sh --confirm destroy-boutique-platform --dry-run
#   ./scripts/operations/teardown.sh --confirm destroy-boutique-platform --destroy-bootstrap
#
# See: docs/setup/13-teardown.md and docs/runbooks/teardown.md
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TF_DEV="${REPO_ROOT}/terraform/environments/dev"
TF_BOOT="${REPO_ROOT}/terraform/bootstrap"
REQUIRED_CONFIRM="destroy-boutique-platform"

CONFIRM_PHRASE=""
DRY_RUN=false
DESTROY_BOOTSTRAP=false

usage() {
  cat <<EOF
Usage: $(basename "$0") --confirm ${REQUIRED_CONFIRM} [options]

Options:
  --confirm PHRASE     Required safety phrase (exact: ${REQUIRED_CONFIRM})
  --dry-run            Run terraform plan -destroy only (dev environment)
  --destroy-bootstrap  Also destroy bootstrap state RG/storage (Topic 01)
  -h, --help           Show this help

Destroys (terraform/environments/dev):
  AKS, ACR, Key Vault, VNet, Azure DNS zone, Log Analytics, platform resource group

Retained by default:
  Terraform remote state backend (bootstrap stack)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --confirm)
      CONFIRM_PHRASE="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --destroy-bootstrap)
      DESTROY_BOOTSTRAP=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "${CONFIRM_PHRASE}" != "${REQUIRED_CONFIRM}" ]]; then
  echo "ERROR: refusing to run without --confirm ${REQUIRED_CONFIRM}" >&2
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "ERROR: Azure CLI (az) not found" >&2
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "ERROR: terraform not found" >&2
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "ERROR: not logged in to Azure — run 'az login'" >&2
  exit 1
fi

SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
echo "=== boutique-aks-devsecops teardown ==="
echo "Subscription: ${SUBSCRIPTION_ID}"
echo "Terraform dev: ${TF_DEV}"
echo "Dry run: ${DRY_RUN}"
echo "Destroy bootstrap: ${DESTROY_BOOTSTRAP}"
echo ""

if [[ ! -d "${TF_DEV}" ]]; then
  echo "ERROR: missing ${TF_DEV}" >&2
  exit 1
fi

if [[ ! -f "${TF_DEV}/terraform.tfvars" ]]; then
  echo "WARN: ${TF_DEV}/terraform.tfvars not found — terraform destroy may prompt for variables or fail"
fi

cd "${TF_DEV}"
echo "=== terraform init (dev) ==="
terraform init -input=false

if [[ "${DRY_RUN}" == true ]]; then
  echo "=== terraform plan -destroy (dry run) ==="
  terraform plan -destroy -input=false
  echo "DRY RUN complete — no resources destroyed"
  exit 0
fi

echo "=== terraform destroy (dev) — this removes AKS, ACR, Key Vault, DNS zone, VNet, LAW ==="
terraform destroy -input=false -auto-approve

echo ""
echo "=== Post-destroy verification ==="
RG_NAME=""
if [[ -f terraform.tfvars ]]; then
  RG_NAME="$(grep -E '^resource_group_name' terraform.tfvars | head -1 | sed -E 's/.*=\s*"([^"]+)".*/\1/' || true)"
fi
if [[ -z "${RG_NAME}" ]]; then
  RG_NAME="rg-boutique-dev-gwc"
  echo "WARN: could not parse resource_group_name from tfvars; checking default ${RG_NAME}"
fi

if az group show --name "${RG_NAME}" >/dev/null 2>&1; then
  echo "WARN: resource group still exists: ${RG_NAME}" >&2
  az resource list --resource-group "${RG_NAME}" -o table || true
else
  echo "OK: platform resource group ${RG_NAME} not found (destroyed)"
fi

AKS_COUNT="$(az aks list --query "length([?contains(name, 'boutique')])" -o tsv 2>/dev/null || echo "?")"
ACR_COUNT="$(az acr list --query "length([?contains(name, 'boutique')])" -o tsv 2>/dev/null || echo "?")"
echo "Remaining boutique AKS clusters (name filter): ${AKS_COUNT}"
echo "Remaining boutique ACR registries (name filter): ${ACR_COUNT}"

KV_NAME=""
if [[ -f terraform.tfvars ]]; then
  KV_NAME="$(grep -E '^key_vault_name' terraform.tfvars | head -1 | sed -E 's/.*=\s*"([^"]+)".*/\1/' || true)"
fi
if [[ -n "${KV_NAME}" ]]; then
  if az keyvault show --name "${KV_NAME}" >/dev/null 2>&1; then
    echo "WARN: Key Vault still active: ${KV_NAME}"
  else
    DELETED="$(az keyvault list-deleted --query "[?name=='${KV_NAME}'].name" -o tsv 2>/dev/null || true)"
    if [[ -n "${DELETED}" ]]; then
      echo "NOTE: Key Vault ${KV_NAME} is soft-deleted. Purge to reuse name:"
      echo "  az keyvault purge --name ${KV_NAME}"
    fi
  fi
fi

if [[ "${DESTROY_BOOTSTRAP}" == true ]]; then
  echo ""
  echo "=== terraform destroy (bootstrap) ==="
  if [[ ! -d "${TF_BOOT}" ]]; then
    echo "ERROR: missing ${TF_BOOT}" >&2
    exit 1
  fi
  cd "${TF_BOOT}"
  terraform init -input=false
  terraform destroy -input=false -auto-approve
  echo "OK: bootstrap stack destroyed"
else
  echo ""
  echo "Bootstrap state storage retained (rebuild: terraform init in dev after re-apply)."
  echo "To remove bootstrap: re-run with --destroy-bootstrap"
fi

echo ""
echo "Teardown script finished. Review docs/setup/13-teardown.md for DNS registrar and ADO cleanup."
