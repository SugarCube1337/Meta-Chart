#!/usr/bin/env bash
set -euo pipefail
TAG="${1:-dev-local}"
for svc in frontend api-gateway user-service order-service notification-worker; do
  docker build -t "${svc}:${TAG}" "services/${svc}"
done
