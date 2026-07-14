#!/usr/bin/env bash
# Rollback smoke test — verify frontend health after Git digest revert + Argo sync.
# Usage: ./tests/integration/rollback-smoke.sh <dev|stage|prod>
set -euo pipefail

ENV="${1:-}"
if [[ -z "${ENV}" ]]; then
  echo "Usage: $0 <dev|stage|prod>" >&2
  exit 2
fi

case "${ENV}" in
  dev)
    HOST="${BOUTIQUE_DEV_HOST:-dev-boutique.biroltilki.art}"
    NS="boutique-dev"
    APP="boutique-dev"
    ;;
  stage)
    HOST="${BOUTIQUE_STAGE_HOST:-stage-boutique.biroltilki.art}"
    NS="boutique-stage"
    APP="boutique-stage"
    ;;
  prod)
    HOST="${BOUTIQUE_PROD_HOST:-boutique.biroltilki.art}"
    NS="boutique-prod"
    APP="boutique-prod"
    ;;
  *)
    echo "Unknown environment: ${ENV}" >&2
    exit 2
    ;;
esac

COOKIE_HEADER="shop_session-id=rollback-smoke"

echo "=== Rollback smoke: ${ENV} ==="
echo "Expecting Argo CD app ${APP} Synced and pods healthy at https://${HOST}"

if command -v kubectl >/dev/null 2>&1; then
  kubectl get application -n argocd "${APP}" -o jsonpath='{.status.sync.status}{" "}{.status.health.status}{"\n"}' 2>/dev/null || true
  kubectl get pods -n "${NS}" -l app=frontend -o wide 2>/dev/null || true
  FRONTEND_IMAGE="$(kubectl get deploy -n "${NS}" frontend -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "unknown")"
  echo "Frontend image: ${FRONTEND_IMAGE}"
fi

HTTP_CODE="$(curl -sS -o /tmp/rollback-smoke.txt -w "%{http_code}" \
  "https://${HOST}/_healthz" \
  -H "Cookie: ${COOKIE_HEADER}" \
  --connect-timeout 15 --max-time 30 || echo "000")"

if [[ "${HTTP_CODE}" != "200" ]]; then
  echo "FAIL: rollback verification — /_healthz returned ${HTTP_CODE}" >&2
  exit 1
fi

echo "PASS: rollback smoke for ${ENV} succeeded"
