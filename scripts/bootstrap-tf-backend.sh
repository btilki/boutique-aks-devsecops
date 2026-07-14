#!/usr/bin/env bash
# Optional helper for Topic 01 — docs/setup/01-terraform-bootstrap.md is authoritative.
# Prints commands and optionally runs bootstrap init/plan/apply from repo root.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_DIR="${REPO_ROOT}/terraform/bootstrap"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap-tf-backend.sh [--dry-run]

Runs terraform init + plan in terraform/bootstrap/.
Does NOT run apply unless you confirm interactively after reviewing the plan.

The Setup Guide (docs/setup/01-terraform-bootstrap.md) remains the source of truth.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ ! -f "${BOOTSTRAP_DIR}/main.tf" ]]; then
  echo "ERROR: ${BOOTSTRAP_DIR}/main.tf not found. Complete Topic 01 file materialization first." >&2
  exit 1
fi

if [[ ! -f "${BOOTSTRAP_DIR}/terraform.tfvars" ]]; then
  echo "ERROR: ${BOOTSTRAP_DIR}/terraform.tfvars missing." >&2
  echo "Copy terraform.tfvars.example and set a globally unique storage_account_name." >&2
  exit 1
fi

run() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "[dry-run] $*"
  else
    echo "+ $*"
    "$@"
  fi
}

cd "${BOOTSTRAP_DIR}"
run terraform init -input=false
run terraform plan -input=false -out=tfplan

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "[dry-run] Skipping apply prompt."
  exit 0
fi

echo
read -r -p "Apply bootstrap plan? This creates billable Azure resources. [y/N] " confirm
if [[ "${confirm}" =~ ^[Yy]$ ]]; then
  terraform apply -input=false tfplan
  echo "Bootstrap apply complete. Run: terraform output"
else
  echo "Apply skipped. Run 'terraform apply tfplan' manually when ready."
fi
