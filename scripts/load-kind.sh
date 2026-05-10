#!/usr/bin/env bash
set -euo pipefail
TAG="${1:-dev-local}"
CLUSTER="${KIND_CLUSTER_NAME:-vkr-demo}"
for svc in frontend api-gateway user-service order-service notification-worker; do
  kind load docker-image "${svc}:${TAG}" --name "${CLUSTER}"
done
