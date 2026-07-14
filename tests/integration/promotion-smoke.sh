#!/usr/bin/env bash
# Stage/prod promotion smoke test — frontend health via ingress.
# Usage: ./tests/integration/promotion-smoke.sh [stage|prod|all]
set -euo pipefail

TARGET="${1:-all}"
COOKIE_HEADER="shop_session-id=promotion-smoke"

check_host() {
  local env="$1"
  local host="$2"
  local ns="$3"

  echo "=== Promotion smoke: ${env} (${host}) ==="

  if command -v kubectl >/dev/null 2>&1; then
    echo "--- Pods (${ns}) ---"
    kubectl get pods -n "${ns}" -o wide 2>/dev/null || echo "WARN: namespace ${ns} not found"
    kubectl get ingress -n "${ns}" boutique-frontend 2>/dev/null || true
  fi

  local code
  code="$(curl -sS -o /tmp/promo-smoke-health.txt -w "%{http_code}" \
    "https://${host}/_healthz" \
    -H "Cookie: ${COOKIE_HEADER}" \
    --connect-timeout 15 --max-time 30 || echo "000")"

  if [[ "${code}" != "200" ]]; then
    echo "FAIL: ${env} /_healthz returned ${code}" >&2
    return 1
  fi

  code="$(curl -sS -o /tmp/promo-smoke-home.txt -w "%{http_code}" \
    "https://${host}/" \
    -H "Cookie: ${COOKIE_HEADER}" \
    --connect-timeout 15 --max-time 30 || echo "000")"

  if [[ "${code}" != "200" ]]; then
    echo "FAIL: ${env} / returned ${code}" >&2
    return 1
  fi

  echo "OK: ${env} promotion smoke passed"
}

STAGE_HOST="${BOUTIQUE_STAGE_HOST:-stage-boutique.biroltilki.art}"
PROD_HOST="${BOUTIQUE_PROD_HOST:-boutique.biroltilki.art}"

FAIL=0
case "${TARGET}" in
  stage) check_host "stage" "${STAGE_HOST}" "boutique-stage" || FAIL=1 ;;
  prod)  check_host "prod" "${PROD_HOST}" "boutique-prod" || FAIL=1 ;;
  all)
    check_host "stage" "${STAGE_HOST}" "boutique-stage" || FAIL=1
    check_host "prod" "${PROD_HOST}" "boutique-prod" || FAIL=1
    ;;
  *)
    echo "Usage: $0 [stage|prod|all]" >&2
    exit 2
    ;;
esac

if [[ "${FAIL}" -ne 0 ]]; then
  exit 1
fi
echo "PASS: promotion smoke (${TARGET})"
