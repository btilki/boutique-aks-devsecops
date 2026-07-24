#!/usr/bin/env bash
# Local equivalent of pipelines/azure-pipelines-pr.yml (Topics 14 + 16).
# Usage: ./tests/ci/pr-validate.sh
# Requires: pre-commit, terraform (>=1.6), checkov, kyverno CLI (see versions.yaml ci.*)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

echo "[pr-validate] pre-commit --all-files"
pre-commit run --all-files --show-diff-on-failure

echo "[pr-validate] terraform validate"
./tests/terraform/validate.sh

echo "[pr-validate] checkov"
./tests/terraform/checkov.sh

echo "[pr-validate] kyverno test"
if ! command -v kyverno >/dev/null 2>&1; then
  echo "ERROR: kyverno CLI not found. Install to match versions.yaml ci.kyverno_cli (e.g. v1.12.6)." >&2
  exit 1
fi
kyverno test policies/tests

echo "[pr-validate] OK — same gates as azure-pipelines-pr.yml"
