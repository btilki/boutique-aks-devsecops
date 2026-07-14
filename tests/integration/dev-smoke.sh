#!/usr/bin/env bash
# Dev environment smoke test — Boutique frontend health via ingress.
# Usage: ./tests/integration/dev-smoke.sh
# Env: BOUTIQUE_DEV_HOST (default dev-boutique.biroltilki.art), KUBE_CONTEXT (optional)
set -euo pipefail

BOUTIQUE_DEV_HOST="${BOUTIQUE_DEV_HOST:-dev-boutique.biroltilki.art}"
NAMESPACE="${BOUTIQUE_NAMESPACE:-boutique-dev}"
COOKIE_HEADER="shop_session-id=smoke-test"

echo "=== Boutique dev smoke test ==="
echo "Host: ${BOUTIQUE_DEV_HOST}"
echo "Namespace: ${NAMESPACE}"

if command -v kubectl >/dev/null 2>&1; then
  if [[ -n "${KUBE_CONTEXT:-}" ]]; then
    kubectl config use-context "${KUBE_CONTEXT}" >/dev/null
  fi
  echo "--- Pod readiness ---"
  kubectl get pods -n "${NAMESPACE}" -o wide
  NOT_READY="$(kubectl get pods -n "${NAMESPACE}" --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "${NOT_READY}" != "0" ]]; then
    echo "WARN: ${NOT_READY} pod(s) not Running — checking details"
    kubectl get pods -n "${NAMESPACE}" --field-selector=status.phase!=Running || true
  fi
  echo "--- Ingress ---"
  kubectl get ingress -n "${NAMESPACE}" boutique-frontend -o wide 2>/dev/null || kubectl get ingress -n "${NAMESPACE}"
fi

echo "--- HTTPS health check ---"
HTTP_CODE="$(curl -sS -o /tmp/boutique-smoke-body.txt -w "%{http_code}" \
  "https://${BOUTIQUE_DEV_HOST}/_healthz" \
  -H "Cookie: ${COOKIE_HEADER}" \
  --connect-timeout 15 --max-time 30 || echo "000")"

if [[ "${HTTP_CODE}" != "200" ]]; then
  echo "FAIL: expected HTTP 200 from /_healthz, got ${HTTP_CODE}" >&2
  head -c 500 /tmp/boutique-smoke-body.txt 2>/dev/null || true
  exit 1
fi

echo "OK: /_healthz returned 200"

echo "--- Frontend page probe ---"
HOME_CODE="$(curl -sS -o /tmp/boutique-home.txt -w "%{http_code}" \
  "https://${BOUTIQUE_DEV_HOST}/" \
  -H "Cookie: ${COOKIE_HEADER}" \
  --connect-timeout 15 --max-time 30 || echo "000")"

if [[ "${HOME_CODE}" != "200" ]]; then
  echo "FAIL: expected HTTP 200 from /, got ${HOME_CODE}" >&2
  exit 1
fi

if ! grep -qi "Online Boutique" /tmp/boutique-home.txt 2>/dev/null; then
  echo "WARN: home page did not contain 'Online Boutique' — verify content manually"
fi

echo "PASS: Boutique dev smoke test succeeded"
