# VKR Meta-Chart v4

Meta-Chart v4 is an integration-oriented version of the Helm metachart for configuration management of multiservice applications.

The project demonstrates the full configuration flow:

```text
values.yaml / environment overrides
        ↓
Helm metachart templates
        ↓
Kubernetes manifests
        ↓
kind/minikube or GitLab CI/CD + Container Registry
```

## Main features

- Hierarchical configuration model: `global → defaults → profiles → services → environment overrides`.
- Five real demo services: `frontend`, `api-gateway`, `user-service`, `order-service`, `notification-worker`.
- Dockerfile for every service.
- Registry-aware image path construction through `global.imageRegistry` and `global.imageTag`.
- Service discovery environment variables generated from `dependencies`.
- Deployment, Service, Ingress, ConfigMap, Secret, ServiceAccount, NetworkPolicy, HPA, ServiceMonitor.
- Optional Istio Gateway, VirtualService and DestinationRule.
- GitLab CI/CD pipeline for validation, image build, push and rendering.
- kind/minikube deployment helpers.

## Local check

```bash
helm lint ./chart
helm template demo ./chart -f ./chart/values-dev.yaml
helm template demo ./chart -f ./chart/values-stage.yaml
helm template demo ./chart -f ./chart/values-prod.yaml
helm template demo ./chart -f ./chart/values-dev.yaml -f ./chart/values-istio.yaml
```

## kind deployment

```bash
kind create cluster --config deploy/kind/kind-config.yaml
./scripts/build-local.sh
./scripts/load-kind.sh
./scripts/deploy-kind.sh
./scripts/smoke-test.sh
```

PowerShell equivalents are available in `scripts/*.ps1`.

## GitLab CI/CD

Push the repository to GitLab. The included `.gitlab-ci.yml` uses GitLab Container Registry variables:

- `CI_REGISTRY`
- `CI_REGISTRY_USER`
- `CI_REGISTRY_PASSWORD`
- `CI_REGISTRY_IMAGE`
- `CI_COMMIT_SHORT_SHA`

The chart can render registry-backed images via:

```bash
helm template demo ./chart \
  -f ./chart/values-dev.yaml \
  --set global.imageRegistry="$CI_REGISTRY_IMAGE" \
  --set global.imageTag="$CI_COMMIT_SHORT_SHA"
```
