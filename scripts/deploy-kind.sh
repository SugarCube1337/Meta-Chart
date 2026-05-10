#!/usr/bin/env bash
set -euo pipefail
NAMESPACE="${NAMESPACE:-demo-app}"
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install demo ./chart -n "${NAMESPACE}" -f ./chart/values-dev.yaml
kubectl get pods,svc,networkpolicy -n "${NAMESPACE}"
