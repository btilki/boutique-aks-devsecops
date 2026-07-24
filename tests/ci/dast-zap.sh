#!/usr/bin/env bash
# Local ZAP baseline helper (Topic 20) — needs Docker + reachable HTTPS target.
# Usage: ./tests/ci/dast-zap.sh [https://dev-boutique.example]
# Default target from versions.yaml hostnames.boutique_dev when arg omitted.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

TARGET="${1:-https://dev-boutique.biroltilki.art}"
ZAP_IMAGE="${ZAP_IMAGE:-ghcr.io/zaproxy/zaproxy:2.15.0}"
OUT_DIR="${OUT_DIR:-${REPO_ROOT}/.zap-out}"
mkdir -p "${OUT_DIR}"

echo "[dast] target=${TARGET}"
echo "[dast] image=${ZAP_IMAGE}"
echo "[dast] out=${OUT_DIR}"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker required" >&2
  exit 1
fi

if ! curl -fsS -o /dev/null --max-time 30 "${TARGET}/"; then
  echo "ERROR: target not reachable — start the platform or pass a live URL." >&2
  exit 1
fi

set +e
docker run --rm \
  -v "${OUT_DIR}:/zap/wrk:rw" \
  "${ZAP_IMAGE}" \
  zap-baseline.py -t "${TARGET}" -r zap-report.html -J zap-report.json -I
RC=$?
set -e

echo "[dast] ZAP rc=${RC} — reports in ${OUT_DIR} (advisory; non-zero rc is OK for triage)"
ls -la "${OUT_DIR}"
exit 0
