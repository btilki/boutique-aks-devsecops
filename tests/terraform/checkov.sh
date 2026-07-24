#!/usr/bin/env bash
# Run Checkov against terraform/ using tests/terraform/.checkov.yaml
# Usage: ./tests/terraform/checkov.sh
# SETUP: docs/setup/16-iac-scanning.md
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

CONFIG="${REPO_ROOT}/tests/terraform/.checkov.yaml"
CHECKOV_VER_HINT="${CHECKOV_VER_HINT:-3.2.510}"

if ! command -v checkov >/dev/null 2>&1; then
  echo "ERROR: checkov not found. Install: pip install \"checkov==${CHECKOV_VER_HINT}\" (see versions.yaml ci.checkov)." >&2
  exit 1
fi

echo "[checkov] version: $(checkov --version)"
echo "[checkov] config: ${CONFIG}"
# --skip-download avoids Bridgecrew guideline API calls (noise / proxy failures in CI)
checkov --config-file "${CONFIG}" --skip-download "$@"
echo "[checkov] OK"
