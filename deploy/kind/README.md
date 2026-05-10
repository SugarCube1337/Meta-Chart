# kind deployment

Create cluster:

```bash
kind create cluster --config deploy/kind/kind-config.yaml
```

Build and load local images:

```bash
./scripts/build-local.sh
./scripts/load-kind.sh
```

Deploy:

```bash
kubectl create namespace demo-app --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install demo ./chart -n demo-app -f ./chart/values-dev.yaml
kubectl get pods,svc,networkpolicy -n demo-app
```
