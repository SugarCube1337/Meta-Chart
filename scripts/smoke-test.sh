#!/usr/bin/env bash
set -euo pipefail
NAMESPACE="${NAMESPACE:-demo-app}"
RELEASE="${RELEASE:-demo}"
SERVICE="${SERVICE:-${RELEASE}-api-gateway}"
LOCAL_PORT="${LOCAL_PORT:-18080}"
kubectl -n "${NAMESPACE}" port-forward "svc/${SERVICE}" "${LOCAL_PORT}:80" >/tmp/vkr-port-forward.log 2>&1 &
PF_PID=$!
trap 'kill ${PF_PID} >/dev/null 2>&1 || true' EXIT
sleep 3
curl -fsS "http://127.0.0.1:${LOCAL_PORT}/health"
echo
curl -fsS "http://127.0.0.1:${LOCAL_PORT}/api/status"
echo
