#!/usr/bin/env bash
# Validate Terraform formatting and configuration for bootstrap and dev environment.
# Usage: tests/terraform/validate.sh
# See docs/setup/02-azure-foundation.md — run after Topic 02 file materialization.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

echo "[validate] terraform fmt -check (tracked .tf only; skips local *.tfvars)"
while IFS= read -r -d '' file; do
  terraform fmt -check "${file}"
done < <(find terraform -type f -name '*.tf' -print0)

echo "[validate] bootstrap module"
(
  cd terraform/bootstrap
  terraform init -backend=false -input=false >/dev/null
  terraform validate
)

echo "[validate] dev environment (Topic 02 modules only)"
(
  cd terraform/environments/dev
  terraform init -backend=false -input=false >/dev/null
  terraform validate
)

echo "[validate] OK"
